package Test::Factory;

use strict;
use warnings;
use utf8;

use String::Random qw(random_regex);
use Exporter::Lite;

our @EXPORT = qw(
     create_user
     create_diary
     create_entry
);

use Diary::Context;
use Diary::Service::User;
use Diary::Service::Diary;

sub create_user {
    my %args = @_;
    my $name = $args{name} // random_regex('test_user_\w{15}');

    my $c = Diary::Context->new;
    my $dbh = $c->dbh;
    $dbh->query(q[ INSERT INTO user (name) VALUES (?) ], [$name] );

    return Diary::Service::User->find_user_by_name($dbh, {
        name => $name
    });
}

sub create_diary {
    my %args  = @_;
    my $user  = $args{user} // create_user();
    my $title = $args{title} // random_regex('\w{50}');

    my $c   = Diary::Context->new;
    my $dbh = $c->dbh;

    $dbh->query( q[ INSERT INTO diary (user_id, title) VALUES (?) ], [$user->user_id, $title] );
    return Diary::Service::Diary->find_diary_by_user( $dbh, { user => $user } );
}

sub create_entry {
   my %args  = @_;
   my $user  = $args{user} // create_user();
   my $diary  = $args{diary} // create_diary(user => $user);
   my $title = $args{title} // random_regex('\w{50}');
   my $content = $args{content} // random_regex('\w{50}');
   my $path = $args{path} // random_regex('\w{50}');
   my $c = Diary::Context->new;
   my $dbh = $c->dbh;
   Diary::Service::Entry->create($dbh, {
       user => $user,
       diary => $diary,
       title => $title,
       content => $content,
       path => $path,
   });
   return Diary::Service::Entry->find_entry_by_path($dbh, {
       user => $user,
       diary => $diary,
       path => $path,
   });
}

1;
