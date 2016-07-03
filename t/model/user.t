package t::Model::User;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

sub _require : Tests(startup) {
    my ($self) = @_;
    require_ok 'Diary::Model::User';
}

sub _accessor : Tests {
    my $user = Diary::Model::User->new(
        user_id => 1,
        name    => "syou6162",
    );

    is $user->user_id, 1;
    is $user->name,    "syou6162";
}

__PACKAGE__->runtests;

1;
