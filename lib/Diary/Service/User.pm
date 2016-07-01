package Diary::Service::User;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Model::User;

sub find_or_create_user_by_name {
    my ( $class, $db, $args ) = @_;
    return $class->find_user_by_name( $db, $args ) // $class->create( $db, $args );
}

sub find_user_by_name {
    my ( $class, $db, $args ) = @_;
    my $name = $args->{name} // croak 'name required';

    my $row = $db->select_row(
        q[ SELECT * FROM user WHERE name = ? ], $name
    ) or return;
    return Diary::Model::User->new($row);
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $name = $args->{name} // croak 'name required';

    $db->query( q[ INSERT INTO user (name) VALUES (?) ], [$name] );
    return $class->find_user_by_name( $db, { name => $name } );
}

1;
