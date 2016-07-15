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

sub find_users_by_user_ids {
    my ( $class, $db, $args ) = @_;
    my $user_ids = $args->{user_ids} // croak 'user_ids required';
    return [] unless scalar @$user_ids;

    return [ map {
        Diary::Model::User->new($_);
    } @{$db->select_all(q[
        SELECT * FROM user
          WHERE user_id IN (?)
    ], $user_ids)} ];
}

sub create {
    my ( $class, $db, $args ) = @_;
    my $name = $args->{name} // croak 'name required';

    $db->query( q[ INSERT INTO user (name) VALUES (?) ], [$name] );
    return $class->find_user_by_name( $db, { name => $name } );
}

sub set_liked_pin {
    my ( $class, $db, $args ) = @_;
    my $name = $args->{name} // croak 'name required';
    my $user = $class->find_or_create_user_by_name( $db, { name => $name } );
    my $entry = $args->{entry} // croak 'entry required';
    my $liked = $args->{liked} ? 1 : 0;
    my $created = $args->{created} || Diary::Util::now;

    $db->query( q[ INSERT INTO liked_pin (user_id, entry_id, liked, created) VALUES (?) ],
                [ $user->user_id, $entry->entry_id, $liked, $created] );

}

1;
