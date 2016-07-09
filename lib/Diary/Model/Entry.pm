package Diary::Model::Entry;
use strict;
use warnings;
use Diary::Util;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(entry_id diary_id user_id title content path)],
    rw  => [qw(user diary)],
);

sub created {
    my ($self) = @_;
    $self->{_created} ||= eval { Diary::Util::datetime_from_db( $self->{created} )};
}

sub load_user {
    my ($class, $db, $entries) = @_;

    my $user_ids = [ map { $_->user_id } @$entries ];
    my $users = Diary::Service::User->find_users_by_user_ids($db, {
        user_ids => $user_ids,
    });

    my $user_map = { map { $_->user_id => $_ } @$users };
    for my $entry (@$entries) {
        $entry->user($user_map->{$entry->user_id});
    }
    return $entries;
}

1;
