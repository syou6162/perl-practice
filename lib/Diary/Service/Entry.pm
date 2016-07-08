package Diary::Service::Entry;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Model::Entry;
use Diary::Util;

sub find_entry_by_entry_id {
    my ( $class, $db, $args ) = @_;
    my $entry_id = $args->{entry_id} // croak 'entry_id required';

    my $row = $db->select_row(
        q[ SELECT * FROM entry WHERE entry_id = ?],
        $entry_id
    ) or return;
    return Diary::Model::Entry->new($row);
}

sub find_entry_by_path {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';
    my $path = $args->{path} // croak 'path required';

    my $row = $db->select_row(
        q[ SELECT * FROM entry WHERE user_id = ? AND diary_id = ? AND path = ?],
        $user_id, $diary_id, $path
    ) or return;
    return Diary::Model::Entry->new($row);
}

sub find_entries_by_user {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';

    my $entries = $db->select_all(
        q[ SELECT * FROM entry WHERE user_id = ? AND diary_id = ? ],
        $user_id, $diary_id
    ) or return;
    return [map Diary::Model::Entry->new($_), @$entries];
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';
    my $title = $args->{title} // croak 'title required';
    my $content = $args->{content};
    my $created = $args->{created} || Diary::Util::now->epoch;
    my $path = $args->{path} || $created;

    $db->query( q[ INSERT INTO entry (diary_id, user_id, title, content, created, path) VALUES (?) ],
                [$diary_id, $user_id, $title, $content, $created, $path] );
    return $class->find_entry_by_path( $db, { user => $user, diary => $diary, created => $created, path => $path } );
}

sub update {
    my ($class, $db, $args) = @_;
    my $user = $args->{user} // croak 'user required';
    my $entry_id = $args->{entry_id} // croak 'entry_id required';
    my $entry = $class->find_entry_by_entry_id($db, {entry_id => $entry_id});
    croak 'Different user name' unless $user->user_id == $entry->user_id;
    my $title = $args->{title} // '';
    my $content = $args->{content} // '';

    $db->query(q[
        UPDATE entry
          SET
            title = ?,
            content = ?
          WHERE
            entry_id = ?
    ], $title, $content, $entry_id);
}

sub delete_entry {
    my ($class, $db, $args) = @_;
    my $user = $args->{user} // croak 'user required';
    my $entry = $args->{entry} // croak 'entry required';
    croak 'Different user name' unless $user->user_id == $entry->user_id;

    $db->query(q[
        DELETE FROM entry
          WHERE
            entry_id = ?
    ], $entry->entry_id);
}

1;
