package Diary::Engine::Index;

use strict;
use warnings;
use utf8;

use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

sub default {
    my ($class, $c) = @_;

    my $user = $c->user;
    return $c->html('index.html') unless $user;

    my $diary = Diary::Service::Diary->find_or_create_diary_by_user($c->dbh, {
        user => $user,
    });

    my $entries = Diary::Service::Entry->find_entries_by_user($c->dbh, {
        user => $user,
        diary => $diary,
    });

    $c->html('index.html', {
        entries => $entries,
    });
}

sub login_get {
    my ($class, $c) = @_;
    print STDERR $class, "aaaa";
    $c->html( 'login.html', {} );
};

sub login_post {
    my ($class, $c) = @_;
    my $name = $c->req->string_param('name');
    my $user = Diary::Service::User->find_or_create_user_by_name($c->dbh, {
        name => $name,
    });

    # リダイレクトするので、リクエストが終わってから入れ替える
    # https://metacpan.org/pod/Plack::Middleware::Session#PLACK-REQUEST-OPTIONS
    $c->request->session_options->{late_store}++;

    $c->session->set($c->session->id, $user->name);
    $c->res->redirect('/');
}

sub logout_post {
    my ($class, $c) = @_;
    $c->session->expire;
    $c->res->redirect('/');
}

1;
__END__
