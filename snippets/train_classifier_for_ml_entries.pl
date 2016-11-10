use strict;
use warnings;

use Encode;
use Text::MeCab;
use Algorithm::LibLinear;
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

my $feature2id = {};

say get_feature_id($feature2id, "a", 0);
say get_feature_id($feature2id, "a", 0);
say get_feature_id($feature2id, "b", 0);
say get_feature_id($feature2id, "c", 1);

sub get_words_from_text {
    my ($mecab, $text) = @_;
    my $node = $mecab->parse($text);
    my $result = [];
    while ($node) {
        my $surface = decode_utf8 $node->surface;
        my $feature = decode_utf8 $node->feature;
        $node = $node->next;
        next unless $surface;
        push @$result, $surface;
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

my $mecab = Text::MeCab->new();
my $text = "日本語の形態素解析のテストを行ってみます";

use Data::Dumper; warn Dumper get_feature_vector($mecab, $feature2id, $text, 0);

sub parse_line {
    my $line = shift;
    my ($url, $label, $title) = split /, /, $line, 3;
    return {
        url => $url,
        label => $label, #$label ? 1 : -1,
        title => $title
    }
}


sub make_training_example {
    my ($mecab, $feature2id, $line) = @_;
    my $result = parse_line($line);
    my $feature = get_feature_vector($mecab, $feature2id, $result->{title}, 0);
    $result->{feature} = $feature;
    return $result;
}

my $test_line = "http://afurotti.hatenablog.com/entry/2016/08/16/213611, 0, 写真の引っ越しができるようになったのね！ - にゃじら的生活＋あるふぁ 猫ふんじゃった";

# use Data::Dumper; warn Dumper make_training_example($mecab, $feature2id, $test_line);

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


my $org_training_data = read_training_data($mecab, $feature2id, "data.txt");

use Clone qw(clone);

my $tmp = [@{clone($org_training_data)}[0..2000]];
for my $example (@$tmp) {
    use Data::Dumper; warn Dumper $example->{label};
    delete $example->{title};
    delete $example->{url};
}

my $data_set = Algorithm::LibLinear::DataSet->new(
    data_set => $tmp
);

# use Data::Dumper; warn Dumper $org_training_data;
# use Data::Dumper; warn Dumper $data_set;

my $learner = Algorithm::LibLinear->new(
    cost => 1.0,  # ペナルティコスト
    epsilon => 0.1,  # 収束判定
    solver => 'L2R_L2LOSS_SVC_DUAL',  # 分類器の学習に使うソルバ
);

my $classifier = $learner->train(data_set => $data_set);

my $accuracy = $learner->cross_validation(
    data_set => $data_set,
    num_folds => 5,
);

say $accuracy;

use Data::Dumper; warn Dumper $tmp->[0];
use Data::Dumper; warn Dumper $classifier->{raw_model}->predict($tmp->[0]);
use Data::Dumper; warn Dumper $classifier->predict(feature => $tmp->[1]->{feature});
use Data::Dumper; warn Dumper $classifier->{raw_model}->predict_values($tmp->[1]->{feature});
use Data::Dumper; warn Dumper $classifier->{raw_model}->num_classes;
# use Data::Dumper; warn say Dumper $classifier->predict_values($tmp->[0]->{feature});
