#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode;
use Text::MeCab;

my $mecab = Text::MeCab->new();
my $text = "日本語の形態素解析のテストを行ってみます";

my $node = $mecab->parse($text);
while($node) {
    my $surface = decode_utf8 $node->surface;
    my $feature = decode_utf8 $node->feature;
    $node = $node->next;
    next unless $surface;
    print encode_utf8 $surface . "(" . [split(",", $feature)]->[0], ")\n";
}
