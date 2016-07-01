package t::Service::User;

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
    require_ok 'Diary::Service::User';
}

sub find_user_by_name : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;
    subtest 'nameないとき失敗する' => sub {
        dies_ok {
            my $user = Diary::Service::User->find_user_by_name($c->dbh, {
            });
        };
    };

    subtest 'user見つかる' => sub {
        my $created_user = create_user;

        my $user = Diary::Service::User->find_user_by_name($c->dbh, {
            name => $created_user->name,
        });

        ok $user, 'userが引ける';
        isa_ok $user, 'Diary::Model::User', 'blessされている';
        is $user->name, $created_user->name, 'nameが一致する';
    };
}

sub create : Tests {
    my ($self) = @_;

    my $c = Diary::Context->new;

    subtest 'ユーザー名わたさないとき失敗する' => sub {
        dies_ok {
            Diary::Service::User->create($c->dbh, {
            });
        };
    };

    subtest 'ユーザー作成できる' => sub {
        my $name = random_regex('test_user_\w{15}');
        Diary::Service::User->create($c->dbh, {
            name => $name,
        });

        my $dbh = $c->dbh;
        my $user = $dbh->select_row(q[
            SELECT * FROM user
              WHERE
                name = ?
        ],  $name);

        ok $user, 'ユーザーできている';
        is $user->{name}, $name, 'nameが一致する';
    };
}

__PACKAGE__->runtests;

1;
