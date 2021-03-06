package t::Service::Diary;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent qw(Test::Class);

use Test::Diary;
use Test::Mechanize;
use Test::Factory;

use Test::More;
use Test::Deep;
use Test::Exception;

use String::Random qw(random_regex);

use Diary::Context;

sub _require : Tests(startup) {
    my ($self) = @_;
    require_ok 'Diary::Service::Entry';
}

sub delete : Test(setup) {
    my $c = Diary::Context->new;
    $c->dbh->query(q[ DELETE FROM entry_tag_map ]);
    $c->dbh->query(q[ DELETE FROM tag ]);
    $c->dbh->query(q[ DELETE FROM entry ]);
    $c->dbh->query(q[ DELETE FROM diary ]);
    $c->dbh->query(q[ DELETE FROM user ]);
}

sub find_entry_by_entry_id : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;
    my $user    = create_user;
    my $diary   = create_diary( user => $user );

    my $expected_entry = Diary::Service::Entry->create($c->dbh, {
        user => $user,
        diary => $diary,
        title => "entry1",
        content => "content1",
        path => "path1",
    });

    my $entry = Diary::Service::Entry->find_entry_by_entry_id($c->dbh, {
        entry_id => $expected_entry->entry_id,
    });
    ok $entry;
    is $entry->title, $expected_entry->title;
}

sub find_entries : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    my $user1    = create_user;
    my $user2    = create_user;
    my $diary1   = create_diary( user => $user1 );
    my $diary2   = create_diary( user => $user2 );

    my $entries = Diary::Service::Entry->find_entries($c->dbh, { });
    is scalar @$entries, 0;

    Diary::Service::Entry->create($c->dbh, {
        user => $user1,
        diary => $diary1,
        title => "entry1",
        content => "content1",
        path => "path1",
    });
    Diary::Service::Entry->create($c->dbh, {
        user => $user2,
        diary => $diary2,
        title => "entry2",
        content => "content2",
        path => "path2",
    });
    $entries = Diary::Service::Entry->find_entries($c->dbh, { });
    is scalar @$entries, 2;
    is $entries->[0]->title, 'entry1';
    is $entries->[1]->title, 'entry2';
}

sub find_entries_by_user : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    my $user    = create_user;
    my $diary   = create_diary( user => $user );

    my $entries = Diary::Service::Entry->find_entries_by_user($c->dbh, {
        user => $user,
        diary => $diary,
    });
    is scalar @$entries, 0;

    Diary::Service::Entry->create($c->dbh, {
        user => $user,
        diary => $diary,
        title => "entry1",
        content => "content1",
        path => "path1",
    });
    Diary::Service::Entry->create($c->dbh, {
        user => $user,
        diary => $diary,
        title => "entry2",
        content => "content2",
        path => "path2",
    });
    $entries = Diary::Service::Entry->find_entries_by_user($c->dbh, {
        user => $user,
        diary => $diary,
    });
    is scalar @$entries, 2;
    is $entries->[0]->title, 'entry1';
    is $entries->[1]->title, 'entry2';
}

sub create : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'エントリ作成できる' => sub {
        my $user    = create_user;
        my $diary   = create_diary( user => $user );
        my $title   = "今日の日記!!!";
        my $content = "暑い!!!";
        my $path    = "hot_day";

        Diary::Service::Entry->create($c->dbh, {
            user => $user,
            diary => $diary,
            title => $title,
            content => $content,
            path => $path,
        });

        my $dbh = $c->dbh;
        my $entry = $dbh->select_row(q[
            SELECT * FROM entry
              WHERE
                user_id = ? AND diary_id = ? AND path = ?
        ],  $user->{user_id}, $diary->{diary_id}, $path);

        ok $entry, 'entryできている';
        is $entry->{title}, $title, 'titleが一致する';
        is $entry->{content}, $content, 'contentが一致する';
        is $entry->{path}, $path, 'pathが一致する';
    };
}

sub update : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'エントリ更新できる' => sub {
        my $user    = create_user;
        my $diary   = create_diary( user => $user );
        my $title   = "今日の日記!!!";
        my $content = "暑い!!!";
        my $path    = "hot_day";

        my $entry = Diary::Service::Entry->create(
            $c->dbh,
            {
                user    => $user,
                diary   => $diary,
                title   => $title,
                content => $content,
                path    => $path,
            }
        );

        my $updated_title   = "明日の日記!!!";
        my $updated_content = "寒い!!!";
        Diary::Service::Entry->update(
            $c->dbh,
            {
                user     => $user,
                entry_id => $entry->entry_id,
                title    => $updated_title,
                content  => $updated_content,
            }
        );

        my $updated_entry = Diary::Service::Entry->find_entry_by_path(
            $c->dbh,
            {
                user  => $user,
                diary => $diary,
                path  => $path,
            }
        );

        ok $updated_entry, 'entryできている';
        is $updated_entry->title, $updated_title, 'titleが一致する';
        is $updated_entry->content, $updated_content, 'contentが一致する';
    };
}

sub delete_entry : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'エントリ更新できる' => sub {
        my $user    = create_user;
        my $diary   = create_diary( user => $user );
        my $title   = "今日の日記!!!";
        my $content = "暑い!!!";
        my $path    = "hot_day";

        my $entry = Diary::Service::Entry->create($c->dbh, {
            user => $user,
            diary => $diary,
            title => $title,
            content => $content,
            path => $path,
        });
        ok $entry, 'entryできている';

        dies_ok { Diary::Service::Entry->delete_entry( $c->dbh, { entry => $entry } ) } "user必須";
        dies_ok { Diary::Service::Entry->delete_entry( $c->dbh, { entry => $entry, user => create_user } ) } "本人じゃないと消せない";
        Diary::Service::Entry->delete_entry( $c->dbh, { entry => $entry, user => $user } );

        ok ! Diary::Service::Entry->find_entry_by_path(
            $c->dbh,
            {
                user => $user,
                diary => $diary,
                path  => $path,
            }
        );
    };
}


__PACKAGE__->runtests;

1;
