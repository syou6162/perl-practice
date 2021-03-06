package Diary::Engine::Entry;

use strict;
use warnings;
use utf8;

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;
use Diary::Util;

sub default {
    my ($class, $c) = @_;
    my $name = $c->req->parameters->{name};
    my $path = $c->req->parameters->{path};

    my $user = Diary::Service::User->find_user_by_name($c->dbh, {
        name => $name,
    });
    my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
        user => $user,
    });
    my $entry = Diary::Service::Entry->find_entry_by_path( $c->dbh, {
        user  => $user,
        diary => $diary,
        path  => $path,
    } );
    Diary::Model::Entry->load_user($c->dbh, [$entry]);
    Diary::Model::Entry->load_tags($c->dbh, [$entry]);
    $c->html( 'entry.html', {
        entry => $entry,
    } );
}

sub add_get {
    my ($class, $c) = @_;
    my $title   = $c->req->string_param('title');
    my $content = $c->req->string_param('content');
    my $path    = $c->req->parameters->{path};

    my $entry;
    if ($path) {
        my $user  = $c->user;
        my $diary = Diary::Service::Diary->find_diary_by_user( $c->dbh, {
            user => $user,
        } );
        $entry = Diary::Service::Entry->find_entry_by_path( $c->dbh, {
            user    => $user,
            diary   => $diary,
            title   => $title,
            content => $content,
            path    => $path,
        } );
    }
    $c->html( 'entry/add.html', {
        entry => $entry,
    } );
}

sub add_post {
    my ($class, $c) = @_;
    my $title   = $c->req->string_param('title');
    my $content = $c->req->string_param('content');
    my $path = $c->req->string_param('path') || Diary::Util::now;

    my $user  = $c->user;
    my $diary = Diary::Service::Diary->find_or_create_diary_by_user( $c->dbh, {
        user  => $user,
    } );

    my $entry = Diary::Service::Entry->find_entry_by_path( $c->dbh, {
        user  => $user,
        diary => $diary,
        path  => $path,
    } );
    if ($entry) {
        Diary::Service::Entry->update( $c->dbh, {
            user     => $user,
            entry_id => $entry->entry_id,
            title    => $title,
            content  => $content,
        } );
    } else {
        Diary::Service::Entry->create( $c->dbh, {
            user    => $user,
            diary   => $diary,
            title   => $title,
            content => $content,
        } );
    }
    $c->res->redirect('/entry?name=' . $user->name . '&path=' . $path);
}

sub delete_get {
    my ($class, $c) = @_;

    my $path = $c->req->parameters->{path};
    return $c->res->redirect('/') unless $path;

    my $user = $c->user;
    my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
        user => $user,
    });
    my $entry = Diary::Service::Entry->find_entry_by_path($c->dbh, {
        user    => $user,
        diary => $diary,
        path => $path,
    });

    $c->html('entry/delete.html', {
        user    => $user,
        entry    => $entry,
    });
}

sub delete_post {
    my ($class, $c) = @_;

    my $path = $c->req->parameters->{path};
    return $c->res->redirect('/') unless $path;

    my $user = $c->user;
    my $diary = Diary::Service::Diary->find_diary_by_user($c->dbh, {
        user => $user,
    });
    my $entry = Diary::Service::Entry->find_entry_by_path($c->dbh, {
        user    => $user,
        diary => $diary,
        path => $path,
    });
    Diary::Service::Entry->delete_entry($c->dbh, { entry => $entry, user => $user });

    $c->res->redirect('/user/' . $user->name);
}

1;
