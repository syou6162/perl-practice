package Diary::Model::Tag;
use strict;
use warnings;
use Diary::Util;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(tag_id entry_id tag)],
);

1;
