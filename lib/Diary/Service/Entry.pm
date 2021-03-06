package Diary::Service::Entry;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Model::Entry;
use Diary::Service::Tag;
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

sub find_entries {
    my ( $class, $db, $args ) = @_;
    my $limit = $args->{limit} || 20;
    my $offset = $args->{offset} || 0;

    my $entries = $db->select_all(
        q[ SELECT * FROM entry ORDER BY created DESC LIMIT ? OFFSET ?],
        $limit, $offset
    ) or return;
    $entries = [map Diary::Model::Entry->new($_), @$entries];
    Diary::Model::Entry->load_user($db, $entries);
    return $entries;
}

sub find_entries_by_user {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';
    my $limit = $args->{limit} || 20;
    my $offset = $args->{offset} || 0;

    my $entries = $db->select_all(
        q[ SELECT * FROM entry WHERE user_id = ? AND diary_id = ? ORDER BY created DESC LIMIT ? OFFSET ?],
        $user_id, $diary_id, $limit, $offset
    ) or return;
    return [map Diary::Model::Entry->new($_), @$entries];
}

sub find_entries_by_user_and_tag {
    my ( $class, $db, $args ) = @_;
    my $username = $args->{username} // croak 'username required';
    my $tag_name = $args->{tag} // croak 'tag required';

    my $user = Diary::Service::User->find_user_by_name($db, {
        name => $username,
    });
    my $diary = Diary::Service::Diary->find_diary_by_user($db, {
        user => $user,
    });
    my $entries = Diary::Service::Entry->find_entries_by_user($db, {
        user  => $user,
        diary => $diary,
    });

    my $tag = Diary::Service::Tag->find_tag_by_name($db, {name => $tag_name});
    my $tag_id = $tag->tag_id;
    my $limit = $args->{limit} || 20;
    my $offset = $args->{offset} || 0;

    my $entry_tag_maps = $db->select_all(
        q[ SELECT * FROM entry_tag_map WHERE entry_id IN (?) AND tag_id = ? LIMIT ? OFFSET ?],
        [map {$_->entry_id} @$entries], $tag_id, $limit, $offset
    ) or return;
    $entries = [map $class->find_entry_by_entry_id($db, {entry_id => $_->{entry_id}}), @$entry_tag_maps];
    Diary::Model::Entry->load_user($db, $entries);
    return $entries;
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';
    my $title = $args->{title} // croak 'title required';
    my $content = $args->{content};
    my $created = $args->{created} || Diary::Util::now;
    my $path = $args->{path} || $created;

    $db->query( q[ INSERT INTO entry (diary_id, user_id, title, content, created, path) VALUES (?) ],
                [$diary_id, $user_id, $title, $content, $created, $path] );
    return $class->find_entry_by_path( $db, { user => $user, diary => $diary, path => $path } );
}

sub update {
    my ($class, $db, $args) = @_;
    my $user = $args->{user} // croak 'user required';
    my $entry_id = $args->{entry_id} // croak 'entry_id required';
    my $entry = $class->find_entry_by_entry_id($db, {entry_id => $entry_id});
    croak 'Different user name' unless $user->user_id == $entry->user_id;
    my $title = $args->{title} || $entry->title;
    my $content = $args->{content} || $entry->content;

    $db->query(q[
        UPDATE entry
          SET
            title = ?,
            content = ?,
            created = created
          WHERE
            entry_id = ?
    ], $title, $content, $entry_id);
}

sub delete_entry {
    my ($class, $db, $args) = @_;
    my $user = $args->{user} // croak 'user required';
    my $entry = $args->{entry} // croak 'entry required';
    croak 'Different user name' unless $user->user_id == $entry->user_id;

    Diary::Service::Tag->delete_tags_by_entry_id($db, {
        entry_id => $entry->entry_id,
    });

    $db->query(q[
        DELETE FROM entry
          WHERE
            entry_id = ?
    ], $entry->entry_id);
}

1;
