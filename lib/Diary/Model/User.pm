package Diary::Model::User;
use strict;
use warnings;
use Carp qw(croak);
use Diary::Util;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(user_id name)],
);

sub created {
    my ($self) = @_;
    $self->{_created} ||= eval { Diary::Util::datetime_from_db( $self->{created} )};
}


sub set_liked_pin {
    my ( $self, $db, $args ) = @_;
    my $entry = $args->{entry} // croak 'entry required';
    my $liked = $args->{liked} ? 1 : 0;
    my $created = $args->{created} || Diary::Util::now;

    $db->query( q[ INSERT INTO liked_pin (user_id, entry_id, liked, created) VALUES (?) ],
                [ $self->user_id, $entry->entry_id, $liked, $created] );
}

1;
