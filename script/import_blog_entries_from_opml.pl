#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use utf8;
use Encode;
use Carp qw(croak);

use WWW::Mechanize;
use XML::Simple;
use XML::Feed;

use Data::Dumper;

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;
use Diary::Service::Tag;
use Diary::Context;
use Diary::Config;

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

sub parse_rss {
    my $content = shift;
    my $data = XML::Feed->parse(\$content) or die XML::Feed->errstr;
    my $user = $data->author || $data->title;
    my $result = {
        title => $data->title,
        user => $user,
        entries => [
            map {
                my $entry = $_;
                {
                    user  => $user,
                        title => $entry->title,
                        content => $entry->content->body,
                        created => $entry->modified,
                    }
            } $data->entries
        ],
    };
    return $result;
}

BEGIN { $ENV{INTERN_BOOKMARK_ENV} = 'local' };
my $context = Diary::Context->from_env(config);
my $mech = WWW::Mechanize->new( autocheck => 0 );
my $blogs_meta_info = get_blogs_meta_info('opml.xml');

foreach my $blog_meta_info (@$blogs_meta_info) {
    $mech->get( $blog_meta_info->{xmlUrl} );
    my $blog;
    if ($mech->status eq '200') {
        eval { $blog = parse_rss $mech->content};
        next unless $blog; # skip invalid rss format
    } else {
        next;
    }
    my $user = Diary::Service::User->find_or_create_user_by_name( $context->dbh, { name => $blog->{user} } );
    my $diary = Diary::Service::Diary->find_or_create_diary_by_user( $context->dbh, { user => $user } );
    for my $entry (@{$blog->{entries}}) {
        my $hash = $entry;
        $hash->{user} = $user;
        $hash->{diary} = $diary;
        my $entry = Diary::Service::Entry->create( $context->dbh, $hash );
        sleep 1;
    }
}
