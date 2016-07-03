package Diary::Model::Entry;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(entry_id diary_id user_id title content)],
    rw  => [qw(user)],
);

1;
