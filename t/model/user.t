package t::Model::User;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

sub _require : Test(startup => 1) {
    my ($self) = @_;
    require_ok 'Model::User';
}

sub _accessor : Test {
    my $user = Model::User->new(
        id   => 1,
        name => "syou6162",
    );

    is $user->id,   1;
    is $user->name, "syou6162";
}

__PACKAGE__->runtests;

1;
