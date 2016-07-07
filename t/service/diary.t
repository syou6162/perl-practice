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
    require_ok 'Diary::Service::Diary';
}

sub find_diary_by_user : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;
    subtest 'userないとき失敗する' => sub {
        dies_ok {
            my $user = Diary::Service::User->find_diary_by_user($c->dbh, { });
        };
    };

    subtest 'diary見つかる' => sub {
        my $user = create_user;
        my $title = 'syou6162の日記';
        Diary::Service::Diary->create($c->dbh, {
            user => $user,
            title => $title,
        });

        my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
            user => $user,
        });

        ok $diary, 'diaryが引ける';
        note explain $diary;
        isa_ok $diary, 'Diary::Model::Diary', 'blessされている';
        is $diary->{title}, $title, 'titleが一致する';
    };
}

sub create : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'titleわたさないとき失敗する' => sub {
        dies_ok {
            Diary::Service::Diary->create($c->dbh, {
            });
        };
    };

    subtest '日記作成できる' => sub {
        my $user = create_user;
        my $title = 'syou6162の日記';
        Diary::Service::Diary->create($c->dbh, {
            user => $user,
            title => $title,
        });

        my $dbh = $c->dbh;
        my $diary = $dbh->select_row(q[
            SELECT * FROM diary
              WHERE
                user_id = ?
        ],  $user->user_id);

        ok $diary, 'ユーザーできている';
        is $diary->{title}, $title, 'titleが一致する';
    };
}

__PACKAGE__->runtests;

1;
