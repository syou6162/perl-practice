use strict;
use warnings;
use 5.010;

my $test_line = "+1 40:0.059549 75:0.059549 97:0.059549 102:0.059549 103:0.059549 149:0.059549 291:0";

sub parse_line {
    my ($line) = shift @_;
    my @tmp      = split /\s/, $line;
    my $label    = int(shift @tmp);
    my $features = [
        map {
            my ( $id, $val ) = split /:/;
            [ int($id), $val + 0.0 ]
        } @tmp
    ];
    [ $label, $features ];
}

&parse_line($test_line);

sub read_data {
    my ($filename) = shift @_;
    my $TRAIN_FH;
    my $train_data = [];
    open $TRAIN_FH, $filename;
    while (<$TRAIN_FH>) {
        chomp;
        push @$train_data, &parse_line($_);
    }
    close $TRAIN_FH;
    $train_data;
}

use Data::Dump qw(dump);

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

# say dump(get_freq([ 1, -1, -1, -1 ], [ 1, 1, 1, -1 ]));

sub get_f_value {
    my ($golds, $predictions) = @_;
    my $freq = get_freq $golds, $predictions;
    my $tp = $freq->{"1,1"} || 0.0;
    my $tn = $freq->{"-1,-1"} || 0.0;
    my $fp = $freq->{"-1,1"} || 0.0;
    my $fn = $freq->{"1,-1"} || 0.0;
    my $recall = $tp / ($tp + $fn);
    my $precision = $tp / ($tp + $fp);
    (2.0 * $recall * $precision) / ($recall + $precision)
}

# say get_f_value([ 1, -1, -1, -1 ], [ 1, 1, 1, -1 ]);

sub update_weight {
    my ( $weight, $features, $pred_label ) = @_;
    foreach my $pair (@$features) {
        my ( $k, $v ) = @$pair;
        $weight->{$k} += $pred_label * $v;
    }
}

sub classify {
    my ($weight, $features) = @_;
    my $sum = 0.0;
    foreach my $pair (@$features) {
	my ($k, $v) = @$pair;
	$sum += ($weight->{$k} || 0.0) * $v;
    }
    if ($sum >= 0) {
	1;
    } else {
	-1;
    }
}

my $weight = {};
update_weight($weight, [[1, 1], [2, 1]], -1);
# say dump($weight);

sub train {
    my ($weight, $golds) = @_;
    foreach my $gold (@$golds) {
	my $label = $gold->[0];
	my $features = $gold->[1];
	my $pred = &classify($weight, $features);
	if ($pred != $gold->[0]) {
	    update_weight($weight, $features, $label);
	}
    }
}

# my $weight = {};
# update_weight($weight, [[1, 1], [2, 1]], -1);
# say dump($weight);
# say &classify($weight, [ [ 1, 1 ], [ 2, 1 ]]);

# my $train_data =
#   [ [ 1, [ [ 1, 1 ], [ 2, 1 ] ] ], [ -1, [ [ 3, 1 ], [ 4, 1 ] ] ] ];

my $train_data = read_data("../data/train.txt");

for my $iter ( 0 .. 9 ) {
    &train( $weight, $train_data );
    my $golds = [ map { $_->[0] } @$train_data ];

    my $predictions = [
        map { &classify( $weight, $_ ) }
        map { $_->[1] } @$train_data
    ];
    eval {
        my $f_value = &get_f_value( $golds, $predictions );
        say "Iter $iter: $f_value";
    };
}
