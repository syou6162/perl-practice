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

__PACKAGE__->runtests;

1;
