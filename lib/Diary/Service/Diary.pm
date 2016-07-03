package Diary::Service::Diary;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Model::Diary;

sub find_or_create_diary_by_user_id {
    my ( $class, $db, $args ) = @_;
    return $class->find_diary_by_user_id( $db, $args ) // $class->create( $db, $args );
}

sub find_diary_by_user_id {
    my ( $class, $db, $args ) = @_;
    my $user_id = $args->{user_id} // croak 'user_id required';

    my $row = $db->select_row(
        q[ SELECT * FROM diary WHERE user_id = ? ], $user_id
    ) or return;
    return Diary::Model::Diary->new($row);
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $user_id = $args->{user_id} // croak 'user_id required';
    my $title = $args->{title} // croak 'title required';

    $db->query( q[ INSERT INTO diary (user_id, title) VALUES (?) ], [$user_id, $title] );
    return $class->find_diary_by_user_id( $db, { user_id => $user_id } );
}

1;
