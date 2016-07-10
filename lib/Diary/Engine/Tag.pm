package Diary::Engine::Tag;
use strict;
use warnings;
use utf8;

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

sub default {
    my ($class, $c) = @_;
    my $username = $c->req->path_parameters->{username};

    my $user = Diary::Service::User->find_user_by_name($c->dbh, {
        name => $username,
    });
    my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
        user => $user,
    });
    my $entries = Diary::Service::Entry->find_entries_by_user($c->dbh, {
        user  => $user,
        diary => $diary,
    });

    my $entry_ids = [map {$_->entry_id} @$entries];
    my $tags = Diary::Service::Tag->find_tags_by_entry_ids($c->dbh, {entry_ids => $entry_ids});
    $c->html( 'tags.html', {
        user => $user,
        tags_ => $tags,
    } );
}

1;
