#!/usr/bin/env perl
use utf8;
use Encode;

my $str = 'あ';
printf "%x\n", ord($str); # 16進数として表示
print encode_utf8 "\x{3042}\n"; # utf8で表示
