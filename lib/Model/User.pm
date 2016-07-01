package Model::User;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(id name)],
);

1;
