package t::Model::Entry;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

sub _require : Tests(startup) {
    my ($self) = @_;
    require_ok 'Diary::Model::Entry';
}

sub _accessor : Tests {
    my $entry = Diary::Model::Entry->new(
        id      => 1,
        title   => "今日の日記",
        content => "今日はTGIFでした",
    );

    is $entry->id,    1;
    is $entry->title, "今日の日記";
}

__PACKAGE__->runtests;

1;
