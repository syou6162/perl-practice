package t::Model::User;
use strict;
use warnings;
use lib 't/lib';
use Diary::Util;
use DateTime::Format::MySQL;
use Test::Diary;

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

__PACKAGE__->runtests;

1;
