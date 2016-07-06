package Diary::Model::User;
use strict;
use warnings;
use Diary::Util;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(user_id name)],
);

sub created {
    my ($self) = @_;
    $self->{_created} ||= eval { Diary::Util::datetime_from_db( $self->{created} )};
}

1;
