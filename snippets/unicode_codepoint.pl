#!/usr/bin/env perl
# http://d.hatena.ne.jp/perlcodesample/20130610/1371002107
use utf8;
use Encode;
use Data::Dumper;

my $str = 'あ';
printf "%x\n", ord($str); # 16進数として表示
print encode_utf8 "\x{3042}\n"; # utf8で表示
print Dumper $str;
