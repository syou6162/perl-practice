#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode;
use Carp qw(croak);

use WWW::Mechanize;
use XML::Simple;

use Data::Dumper;

sub is_rss_info {
    my $info = shift;
    return $info &&
        ref($info) eq 'HASH' &&
        $info->{title} &&
        $info->{xmlUrl};
}

sub _extract_outlines {
    my ($candidate, $result) = @_;
    if (is_rss_info($candidate)) {
        push @$result, $candidate;
    } elsif ($candidate->{outline}) {
        if (ref($candidate->{outline}) eq 'HASH') {
            push @$result, $candidate->{outline};
        } elsif (ref($candidate->{outline}) eq 'ARRAY') {
            foreach (@{$candidate->{outline}}) {
                push @$result, $_;
            }
        }
    } else {
        croak 'something wrong!!!';
    }
    return $result;
}

sub extract_outlines {
    my $candidate = shift;
    _extract_outlines($candidate, []);
}

sub get_blogs_meta_info {
    my $filename = shift;

    my $xml = XML::Simple->new;
    my $data = $xml->XMLin($filename);

    my $outlines = [];
    foreach (@{$data->{body}->{outline}->{outline}}) {
        push(@$outlines, @{extract_outlines($_)});
    }
    return $outlines;
}

my $mech = WWW::Mechanize->new( autocheck => 0 );
my $blogs_meta_info = get_blogs_meta_info('opml.xml');
foreach my $blog_meta_info (@$blogs_meta_info) {
    $mech->get( $blog_meta_info->{xmlUrl} );
    print $mech->content if $mech->status eq '200';
}
