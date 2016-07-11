package t::Diary::Engine::API::Entry;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent qw(Test::Class);

use Test::Diary;
use Test::Mechanize qw(create_mech);
use Test::Factory qw(
    create_user create_diary create_entry
);

use Test::More;
use Test::Mock::Guard qw(mock_guard);

use URI;
use URI::QueryParam;

use Diary::Context;
use Diary::Model::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

sub update : Tests {
    my $c = Diary::Context->new;
    my $user  = create_user;
    my $diary = create_diary(user => $user);
    my $entry = create_entry(user => $user, diary => $diary);
    my $mech = create_mech(user => $user);

    my $title = "タイトル";
    my $content = "ないよー";
    $mech->post_ok('/api/entry/update',
                   {
                       entry_id => $entry->entry_id,
                       title => $title,
                       content => $content,
                   });
    note explain $mech->content;
    $entry = Diary::Service::Entry->find_entry_by_entry_id($c->dbh, {
        entry_id => $entry->entry_id,
    });
    is $entry->title, $title;
    is $entry->content, $content;
}

__PACKAGE__->runtests;

1;
