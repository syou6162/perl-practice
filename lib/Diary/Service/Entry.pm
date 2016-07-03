package Diary::Service::Entry;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Model::Entry;

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

sub create {
    my ( $class, $db, $args ) = @_;
    my $user = $args->{user} // croak 'user required';
    my $user_id = $user->{user_id} // croak 'user_id required';
    my $diary = $args->{diary} // croak 'diary required';
    my $diary_id = $diary->{diary_id} // croak 'diary_id required';
    my $title = $args->{title} // croak 'title required';
    my $content = $args->{content};
    my $path = $args->{path};

    $db->query( q[ INSERT INTO entry (diary_id, user_id, title, content, path) VALUES (?) ],
                [$diary_id, $user_id, $title, $content, $path] );
    return $class->find_entry_by_path( $db, { user => $user, diary => $diary, path => $path } );
}

1;
