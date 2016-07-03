package Diary::Model::User;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(user_id name)],
);

1;
