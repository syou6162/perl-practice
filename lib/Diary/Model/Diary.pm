package Diary::Model::Diary;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(diary_id user_id title)],
    rw  => [qw(user)],
);

1;
