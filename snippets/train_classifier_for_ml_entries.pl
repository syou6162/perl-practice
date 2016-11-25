use strict;
use warnings;

use utf8;
use Encode;
use Text::MeCab;
use Algorithm::LibLinear;
use LWP::Simple;
use Clone qw(clone);
use List::UtilsBy qw( nsort_by rev_nsort_by uniq_by );
use WebService::Slack::IncomingWebHook;
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
    my ($mecab, $feature2id, $text, $is_test) = @_;
    my $result = {};
    my @word_ids = map { get_feature_id( $feature2id, $_, $is_test ) } @{ get_words_from_text( $mecab, $text ) };
    foreach my $word (@word_ids) {
        $result->{$word} = 1;
    }
    return $result;
}

sub parse_line {
    my $line = shift;
    my ($url, $label, $title) = split /, /, $line, 3;
    return {
        url => $url,
        label => $label ? 1 : -1,
        title => $title
    }
}

sub get_title {
    my $url = shift;
    my $html = get($url);
    my $title = "";
    if ($html && $html =~ m{<TITLE>(.*?)</TITLE>}gism) {
        $title = $1;
        $title =~ s/\n/ /g;
    }
    return $title;
}

sub make_training_example {
    my ($mecab, $feature2id, $line) = @_;
    my $result = parse_line($line);
    my $feature = get_feature_vector($mecab, $feature2id, $result->{title}, 0);
    $result->{feature} = $feature;
    return $result;
}

sub make_test_example {
    my ($mecab, $feature2id, $url) = @_;
    my $title = get_title($url);
    my $feature = get_feature_vector($mecab, $feature2id, $title, 1);
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

my $feature2id = {};
my $mecab = Text::MeCab->new();

my $org_training_data = read_training_data($mecab, $feature2id, "data.txt");
my $tmp_train = [@{clone($org_training_data)}];
for my $example (@$tmp_train) {
    delete $example->{title};
    delete $example->{url};
}
my $data_set = Algorithm::LibLinear::DataSet->new(
    data_set => $tmp_train
);

my $learner = Algorithm::LibLinear->new(
    cost => 1.0,  # ペナルティコスト
    epsilon => 0.0001,  # 収束判定
    solver => 'L2R_L2LOSS_SVC_DUAL',  # 分類器の学習に使うソルバ
);
my $classifier = $learner->train(data_set => $data_set);

# for my $example (@$org_training_data) {
#     my $score = $classifier->{raw_model}->predict_values($example->{feature})->[0];
#     $example->{score} = $score;
# }
# for my $example (uniq_by {$_->{title}} uniq_by {$_->{url}} nsort_by {abs($_->{score})} @$org_training_data) {
#     say $example->{score} . " " . $example->{title};
# }

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
    if ($example->{score} > 0) {
        $client->post(
            username   => 'ML君',
            text       => "<$example->{url}|$example->{title}>",
        );
        warn say encode_utf8 $example->{score} . " " . $example->{title};
    }
}
