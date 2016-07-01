package Diary::Model::Diary;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(id title)],
);

1;
