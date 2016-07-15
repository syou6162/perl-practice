package t::Model::User;
use strict;
use warnings;
use lib 't/lib';
use Diary::Util;
use DateTime::Format::MySQL;
use Test::Diary;

use Test::Factory;

use parent qw(Test::Class);
use Test::More;

sub _require : Tests(startup) {
    my ($self) = @_;
    require_ok 'Diary::Model::User';
}

sub _accessor : Tests {
    my $now = Diary::Util::now;
    my $user = Diary::Model::User->new(
        user_id => 1,
        name    => "syou6162",
        created => DateTime::Format::MySQL->format_datetime($now),
    );
    is $user->user_id, 1;
    is $user->name,    "syou6162";
    is $user->created->epoch, $now->epoch;
}

sub set_liked_pin : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'ピンが設定できる' => sub {
        my $user = create_user;
        my $entry1 = create_entry;
        my $entry2 = create_entry;
        $user->set_liked_pin( $c->dbh, {
            name  => $user->name,
            entry => $entry1,
            liked => 1,
        } );
        ok 1;
    };
}

__PACKAGE__->runtests;

1;
