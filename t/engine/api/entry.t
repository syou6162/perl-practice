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
use JSON::XS qw(decode_json);

use Diary::Context;
use Diary::Model::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

sub update : Tests {
    my $c     = Diary::Context->new;
    my $user  = create_user;
    my $diary = create_diary( user => $user );
    my $entry = create_entry( user => $user, diary => $diary );
    my $mech  = create_mech( user => $user );

    my $title   = "タイトル";
    my $content = "ないよー";
    $mech->post_ok(
        '/api/entry/update',
        {
            entry_id => $entry->entry_id,
            title    => $title,
            content  => $content,
        }
    );
    $entry = Diary::Service::Entry->find_entry_by_entry_id( $c->dbh, { entry_id => $entry->entry_id, } );
    is $entry->title,   $title;
    is $entry->content, $content;
}

sub delete : Tests {
    my $c     = Diary::Context->new;
    my $user  = create_user;
    my $diary = create_diary( user => $user );
    my $mech  = create_mech( user => $user );

    subtest '正常にエントリが削除できる' => sub {
        my $entry = create_entry( user => $user, diary => $diary );

        $mech->post_ok(
            '/api/entry/delete',
            {
                entry_id => $entry->entry_id,
            }
        );
        is $mech->res->code, 200, '200が返る';
        is_deeply decode_json $mech->content, {};
        $entry = Diary::Service::Entry->find_entry_by_entry_id( $c->dbh, { entry_id => $entry->entry_id, } );
        ok ! $entry;
    };

    subtest 'エントリが存在しないので削除できない' => sub {
        my $entry = create_entry( user => $user, diary => $diary );

        my $not_existing_entry_id = -1;
        # $mech->post_ok(
        #     '/api/entry/delete',
        #     {
        #         entry_id => $not_existing_entry_id,
        #     }
        # );
        # is $mech->res->code, 500, '500が返る';
        # $entry = Diary::Service::Entry->find_entry_by_entry_id( $c->dbh, { entry_id => $entry->entry_id, } );
        # ok ! $entry;
    };
}

__PACKAGE__->runtests;

1;
