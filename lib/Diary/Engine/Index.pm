package Diary::Engine::Index;

use strict;
use warnings;
use utf8;

use Diary::Service::Diary;
use Diary::Service::Entry;

sub default {
    my ($class, $c) = @_;

    my $user = $c->user;
    return $c->html('index.html') unless $user;

    my $diary = Diary::Service::Diary->find_or_create_diary_by_user($c->dbh, {
        user => $user,
        title => $user->name . "の日記",
    });

    my $entries = Diary::Service::Entry->find_entries_by_user($c->dbh, {
        user => $user,
        diary => $diary,
    });

    $c->html('index.html', {
        entries => $entries,
    });
}

1;
__END__
