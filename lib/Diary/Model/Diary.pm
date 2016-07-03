package Diary::Model::Diary;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(diary_id user_id title)],
);

1;
