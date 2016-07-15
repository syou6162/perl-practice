package t::Diary::Engine::User;

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

sub default : Tests {
    my $c = Diary::Context->new;
    my $user  = create_user;
    my $name = $user->name;
    my $diary = create_diary(user => $user);
    my $entry = create_entry(user => $user, diary => $diary);
    my $mech = create_mech(user => $user);

    my $title = "タイトル";
    my $content = "ないよー";
    subtest '新規作成' => sub {
        $mech->get_ok("/user/$name");
    };
}

__PACKAGE__->runtests;

1;
