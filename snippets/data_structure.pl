use strict;
use warnings;
use 5.010;

my @list = ( 1, 2, 3, 4 );

use Data::Dumper;
print Dumper(\@list);

use Data::Dump qw(dump);
print dump(\@list);

use Data::Printer;
say p(@list);

my $fruits = [ "pineapple", "papaya", "mango" ];

say $fruits;
say dump($fruits);

my $ref_to_gilligan_info = {
    name     => "gillian",
    hat      => "White",
    shirt    => "red",
    position => "first mate",
};

say dump($ref_to_gilligan_info);

# 無名hashへのアクセス
say $ref_to_gilligan_info->{hat};
