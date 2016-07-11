package Diary::Engine::API::Entry;

use strict;
use warnings;
use utf8;
use Carp qw(croak);

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;
use Diary::Util;

sub update {
    my ($class, $c) = @_;
    my $user = $c->user;
    my $entry_id = $c->req->parameters->{entry_id} // croak 'entry_id required';
    my $entry = Diary::Service::Entry->find_entry_by_entry_id($c->dbh, {
        entry_id => $entry_id,
    });
    my $title = $c->req->parameters->{title} || $entry->title;
    my $content = $c->req->parameters->{content} || $entry->content;
    Diary::Service::Entry->update($c->dbh, {
        user => $user,
        entry_id => $entry_id,
        title => $title,
        content => $content,
    });

    $c->json({
    });
}

1;