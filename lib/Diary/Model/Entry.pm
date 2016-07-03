package Diary::Model::Entry;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(entry_id title content)],
);

1;
