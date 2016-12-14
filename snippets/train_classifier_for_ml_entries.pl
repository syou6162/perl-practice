use strict;
use warnings;

use utf8;
use Encode;
use Text::MeCab;
use JSON::Types;
use Algorithm::LibLinear;
use LWP::Simple;
use JSON::XS;
use Clone qw(clone);
use List::Util qw(shuffle reduce min);
use List::UtilsBy qw( nsort_by rev_nsort_by uniq_by );
use WebService::Slack::IncomingWebHook;
use WebService::Mackerel;
use HTML::ExtractContent;
use v5.10;

sub get_feature_id {
    my ($feature2id, $feature, $is_test) = @_;
    if (exists($feature2id->{$feature})) {
        return $feature2id->{$feature};
    } elsif ($is_test) {
        return 1;
    } else {
        $feature2id->{$feature} = 2 + scalar keys $feature2id;
    }
};

sub get_words_from_text {
    my ($mecab, $text) = @_;
    my $node = $mecab->parse($text);
    my $result = [];
    while ($node) {
        my $surface = decode_utf8 $node->surface;
        my $feature = decode_utf8 $node->feature;
        $node = $node->next;
        next unless $surface;
        push @$result, $surface if [split(",", $feature)]->[0] eq "名詞";
    }
    return $result;
}

sub get_feature_vector {
    my ($mecab, $feature2id, $prefix, $text, $is_test) = @_;
    my $result = {};
    my @words = @{ get_words_from_text( $mecab, $text ) };
    my @word_ids = map { get_feature_id( $feature2id, $prefix . ":" . $_, $is_test ) } @words;
    # my @word_ids = map { get_feature_id( $feature2id, $prefix . ":" . $_, $is_test ) } @words[0..min(300, scalar @words - 1)];
    foreach my $word (@word_ids) {
        $result->{$word} = 1;
    }
    return $result;
}

sub parse_line {
    my $line = shift;
    my $result = JSON::XS::decode_json $line;
    $result->{label} = $result->{label} ? 1 : -1;
    return $result;
}

sub get_html {
    my $url = shift;
    my $html = get($url);
}

sub get_title {
    my $html = shift;
    my $title = "";
    if ($html && $html =~ m{<TITLE>(.*?)</TITLE>}gism) {
        $title = $1;
        $title =~ s/\n/ /g;
    }
    return $title;
}

sub get_content {
    my $html = shift;
    my $extractor = HTML::ExtractContent->new;
    $extractor->extract($html);
    return encode_utf8 $extractor->as_text;
}

sub make_training_example {
    my ($mecab, $feature2id, $line) = @_;
    my $result = parse_line($line);
    my $feature = {
        %{get_feature_vector($mecab, $feature2id, "title", $result->{title}, 0)},
        %{get_feature_vector($mecab, $feature2id, "content", $result->{content}, 0)},
    };
    $result->{feature} = $feature;
    return $result;
}

sub make_test_example {
    my ($mecab, $feature2id, $url) = @_;
    my $html = get_html($url);
    my $title = get_title($html);
    my $content = get_content($html);
    my $feature = {
        %{get_feature_vector($mecab, $feature2id, "title", $title, 1)},
        %{get_feature_vector($mecab, $feature2id, "content", $content, 1)},
    };
    sleep 1;
    warn encode_utf8 $title;
    warn $url;
    my $result = {
        url => $url,
        title => $title,
        feature => $feature
    };
    return $result;
}

sub read_training_data {
    my ($mecab, $feature2id, $filename) = @_;
    my $TRAIN_FH;
    my $train_data = [];
    open $TRAIN_FH, $filename;
    while (<$TRAIN_FH>) {
        chomp;
        push @$train_data, make_training_example($mecab, $feature2id, $_);
    }
    close $TRAIN_FH;
    $train_data;
}

sub get_freq {
    my ( $golds, $predictions ) = @_;
    my $result = {};
    my $pair;
    for my $idx ( 0 .. @$golds - 1 ) {
        $pair = "$golds->[$idx],$predictions->[$idx]";
        $result->{$pair} += 1;
    }
    $result;
}

sub get_evaluation_metrics {
    my ($golds, $predictions) = @_;
    my $freq = get_freq $golds, $predictions;
    my $tp = $freq->{"1,1"} || 0.0;
    my $tn = $freq->{"-1,-1"} || 0.0;
    my $fp = $freq->{"-1,1"} || 0.0;
    my $fn = $freq->{"1,-1"} || 0.0;
    my $recall = $tp / ($tp + $fn);
    my $precision = $tp / ($tp + $fp);
    return {
        recall    => $recall,
        precision => $precision,
        f_value   => ( 2.0 * $recall * $precision ) / ( $recall + $precision ),
    };
}

sub under_sampling {
    my ($data) = @_;
    my $result = [grep {$_->{label} == 1} @$data];
    my $minor_cnt = scalar @$result;
    my $cnt = 0;
    for my $example (shuffle grep {$_->{label} == -1} @$data) {
        last if $cnt > $minor_cnt;
        if ($example->{label} == -1) {
            push @$result, $example;
            $cnt++;
        }
    }
    return $result;
}

sub over_sampling {
    my ($data) = @_;
    my $result = [grep {$_->{label} == -1} @$data];
    my $major_cnt = scalar @$result;
    my $cnt = 0;
    my $pos_examples = [shuffle grep {$_->{label} == 1} @$data];
    while(1) {
        last if $cnt > $major_cnt;
        use Data::Dumper; warn Dumper int(rand(scalar @$pos_examples - 1));
        push @$result, @$pos_examples[int(rand(scalar @$pos_examples - 1))];
        $cnt++;
    }
    return $result;
}

sub get_dev_evaluation_metrics {
    my ($data, $cost, $epsilon, $solver) = @_;
    $data = [shuffle @$data];
    my $train = [@$data[0..(scalar @$data * 0.8)]];
    my $dev = [@$data[(scalar @$data * 0.8) + 1 .. scalar @$data - 1]];
    # どっちもうまく精度が上がってくれない...
    # $train = under_sampling($train);
    # $train = over_sampling($train);
    my $data_set = Algorithm::LibLinear::DataSet->new(
        data_set => $train
    );
    my $learner = Algorithm::LibLinear->new(
        cost => $cost,
        epsilon => $epsilon,
        solver => $solver,
    );
    my $classifier = $learner->train(data_set => $data_set);

    my $predictions = [];
    for my $example (@$dev) {
        push @$predictions, $classifier->predict(feature => $example->{feature});
    }
    return get_evaluation_metrics([map {$_->{label}} @$dev], $predictions);
}

sub get_averaged_dev_evaluation_metrics {
    my ($data, $n, $cost, $epsilon, $solver) = @_;
    my $result = [];
    for my $i (0..$n) {
        $data = [shuffle @$data];
        push @$result, get_dev_evaluation_metrics($data, $cost, $epsilon, $solver);
    }
    return {
        recall => (reduce { $a + $b->{recall}} 0.0, @$result) / $n,
        precision  => (reduce { $a + $b->{precision}} 0.0, @$result) / $n,
        f_value => (reduce { $a + $b->{f_value}} 0.0, @$result) / $n,
    };
}

my $feature2id = {};
my $mecab = Text::MeCab->new();

my $org_training_data = read_training_data($mecab, $feature2id, "data.txt");
my $tmp = [@{clone($org_training_data)}];
my $titles = {};
for my $example (@$tmp) {
    $titles->{$example->{title}} = 1;
    delete $example->{title};
    delete $example->{content};
    delete $example->{url};
}

$tmp = [shuffle @$tmp];

my $data_set = Algorithm::LibLinear::DataSet->new(
    data_set => $tmp
);

my $cost = 1.0;
my $epsilon = 0.0000001;
# my $solver = 'L2R_L2LOSS_SVC_DUAL';
my $solver = "L2R_LR";

my $learner = Algorithm::LibLinear->new(
    cost => $cost,  # ペナルティコスト
    epsilon => $epsilon,  # 収束判定
    solver => $solver,  # 分類器の学習に使うソルバ
);

my $classifier = $learner->train(data_set => $data_set);

my $metrics = get_averaged_dev_evaluation_metrics($tmp, 30, $cost, $epsilon, $solver);

my $mackerel = WebService::Mackerel->new(
    api_key => $ENV{ML_STUDY_MACKEREL_API_KEY},
    service_name => 'ML-Study',
);

my $res1 = $mackerel->post_service_metrics(
    [
        {
            "name"  => "evaluation.precision",
            "time"  => time,
            "value" => JSON::Types::number $metrics->{precision},
        },
        {
            "name"  => "evaluation.recall",
            "time"  => time,
            "value" => JSON::Types::number $metrics->{recall},
        },
        {
            "name"  => "evaluation.f_value",
            "time"  => time,
            "value" => JSON::Types::number $metrics->{f_value},
        },
    ]
);

my $res2 = $mackerel->post_service_metrics(
    [
        {
            "name"  => "count.positive",
            "time"  => time,
            "value" => scalar grep {$_->{label}  == 1} @$tmp,
        },
        {
            "name"  => "count.negative",
            "time"  => time,
            "value" => scalar grep {$_->{label}  == -1} @$tmp,
        },
    ]
);

for my $example (@$org_training_data) {
    my $score = $classifier->{raw_model}->predict_values($example->{feature})->[0];
    $example->{score} = $score;
}
for my $example (uniq_by {$_->{title}} uniq_by {$_->{url}} nsort_by {abs($_->{score})} @$org_training_data) {
    say encode_utf8 $example->{score} . " " . $example->{title} if $example->{label} == -1;
}

my $test_examples = [];

while (<STDIN>){
    chomp($_);
    push @$test_examples, make_test_example($mecab, $feature2id, $_);
}

for my $example (@$test_examples) {
    my $score = $classifier->{raw_model}->predict_values($example->{feature})->[0];
    $example->{score} = $score;
}

my $client = WebService::Slack::IncomingWebHook->new(
    webhook_url => $ENV{ML_STUDY_WEBHOOK_URL}
);

my $spreadsheet_url = $ENV{ML_STUDY_SPREADSHEET_URL};
$client->post(
    username   => 'ML君',
    text       => "ml-study向けにこんなエントリはどうですか?教師データを追加/編集したい場合は<$spreadsheet_url|こちら>をどうぞ!",
);

for my $example (uniq_by {$_->{title}} uniq_by {$_->{url}} rev_nsort_by {$_->{score}} @$test_examples) {
    if (not exists($titles->{$example->{title}}) && $example->{score} > 0) {
        $client->post(
            username   => 'ML君',
            text       => "<$example->{url}|$example->{title}>",
        );
        warn say encode_utf8 $example->{score} . " " . $example->{title};
    }
}
