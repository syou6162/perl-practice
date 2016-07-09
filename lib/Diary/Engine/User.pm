package Diary::Engine::User;

use strict;
use warnings;
use utf8;

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

use Data::Dumper;

sub default {
    my ($class, $c) = @_;
    my $username = $c->req->path_parameters->{username};
    # my $name = $c->req->parameters->{name};
    # my $path = $c->req->parameters->{path};

    my $user = Diary::Service::User->find_user_by_name($c->dbh, {
        name => $username,
    });
    my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
         user => $user,
     });
    my $entries = Diary::Service::Entry->find_entries_by_user( $c->dbh, {
        user  => $user,
        diary => $diary,
    } );
    Diary::Model::Entry->load_user($c->dbh, $entries);
    $c->html( 'index.html', {
        entries => $entries,
    } );
}

1;
