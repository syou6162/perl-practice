package Diary::Service::Tag;
use strict;
use warnings;
use List::MoreUtils qw/uniq/;
use Carp qw(croak);
use Diary::Model::Tag;
use Diary::Util;

sub find_tags_by_entry_id {
    my ( $class, $db, $args ) = @_;
    my $entry_id = $args->{entry_id} // croak 'entry_id required';

    my $mapping = $db->select_all(
        q[ SELECT * FROM entry_tag_map WHERE entry_id = ?],
        $entry_id
    ) or return;
    my $tag_ids = [map {$_->{tag_id}} @$mapping];
    my $tags = [map $class->find_tag_by_tag_id($db, {tag_id => $_}), @$tag_ids];
    return $tags;
}

sub find_tags_by_entry_ids {
    my ( $class, $db, $args ) = @_;
    my $entry_ids = $args->{entry_ids} // croak 'entry_ids required';

    my $mapping = $db->select_all(
        q[ SELECT * FROM entry_tag_map WHERE entry_id IN (?) ],
        $entry_ids
    ) or return;
    my $tag_ids = [map {$_->{tag_id}} @$mapping];
    my $tags = [map $class->find_tag_by_tag_id($db, {tag_id => $_}),  uniq @$tag_ids];
    return $tags;
}

sub find_tag_by_tag_id {
    my ( $class, $db, $args ) = @_;
    my $tag_id = $args->{tag_id} // croak 'tag_id required';

    my $row = $db->select_row(
        q[ SELECT * FROM tag WHERE tag_id = ?],
        $tag_id
    ) or return;
    return Diary::Model::Tag->new($row);
}

sub find_tag_by_name {
    my ( $class, $db, $args ) = @_;
    my $name = $args->{name} // croak 'name required';

    my $row = $db->select_row(
        q[ SELECT * FROM tag WHERE name = ?],
        $name
    ) or return;
    return Diary::Model::Tag->new($row);
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $entry = $args->{entry} // croak 'entry required';
    my $entry_id = $entry->{entry_id};
    my $name = $args->{tag} // croak 'tag required';
    my $created = $args->{created} || Diary::Util::now;

    my $tag = $class->find_tag_by_name($db, {name => $name});
    $db->query( q[ INSERT INTO tag (name, created) VALUES (?) ], [$name, $created] ) unless $tag;
    $tag = $class->find_tag_by_name($db, {name => $name});
    $db->query( q[ INSERT INTO entry_tag_map (entry_id, tag_id) VALUES (?) ], [$entry_id, $tag->tag_id] );
}

sub delete_tags_by_entry_id {
    my ( $class, $db, $args ) = @_;
    my $entry_id = $args->{entry_id} // croak 'entry_id required';
    my $tags = $class->find_tags_by_entry_id($db, $args);
    $db->query(q[ DELETE FROM entry_tag_map WHERE entry_id = ? AND tag_id IN (?) ],
               $entry_id, [map {$_->{tag_id}} @$tags]) if @$tags;
}

1;
