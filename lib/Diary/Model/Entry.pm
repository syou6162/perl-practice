package Diary::Model::Entry;
use strict;
use warnings;
use Diary::Service::Tag;
use Diary::Service::User;
use Diary::Util;
use JSON::Types;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(entry_id diary_id user_id title content path)],
    rw  => [qw(user diary tags)],
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

sub load_tags {
    my ($class, $db, $entries) = @_;

    my $entry_ids = [ map { $_->entry_id } @$entries ];
    foreach my $entry (@$entries) {
        my $entry_id = $entry->entry_id;
        my $tags = Diary::Service::Tag->find_tags_by_entry_id($db, {
            entry_id => $entry_id,
        });
        $entry->tags($tags);
    }
    return $entries;
}

sub to_json {
    my $self = shift;
    return {
        # Tagもoptionalに入れられるようにしたい
        entry_id => JSON::Types::number $self->entry_id,
        diary_id => JSON::Types::number $self->diary_id,
        user_id  => JSON::Types::number $self->user_id,
        title    => JSON::Types::string $self->title,
        content  => JSON::Types::string $self->content,
        path     => JSON::Types::string $self->path,
        created  => JSON::Types::string $self->created,
    };
}

1;
