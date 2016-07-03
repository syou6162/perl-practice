package Test::Factory;

use strict;
use warnings;
use utf8;

use String::Random qw(random_regex);
use Exporter::Lite;

our @EXPORT = qw(
     create_user
     create_diary
);

#use Intern::Bookmark::Util;
use Diary::Context;
use Diary::Service::User;
use Diary::Service::Diary;
#use Entry;

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

# sub create_entry {
#     my %args = @_;
#     my $url      = $args{url} // 'http://' . random_regex('\w{15}') . '.com/';
#     my $title    = $args{title} // random_regex('\w{50}');
#     my $created  = $args{created} // Intern::Bookmark::Util::now;
#     my $updated  = $args{updated} // Intern::Bookmark::Util::now;

#     my $c = Intern::Bookmark::Context->new;
#     my $dbh = $c->dbh;
#     $dbh->query(q[
#         INSERT INTO entry (url, title, created, updated)
#           VALUES (?)
#     ], [ $url, $title, $created, $updated ]);

#     return Intern::Bookmark::Service::Entry->find_entry_by_url($dbh, {
#         url => $url
#     });
# }

# sub create_bookmark {
#     my %args = @_;
#     my $user    = $args{user}    // create_user();
#     my $entry   = $args{entry}   // create_entry();
#     my $comment = $args{comment} // random_regex('\w{50}');
#     my $created = $args{created} // Intern::Bookmark::Util::now;
#     my $updated = $args{updated} // Intern::Bookmark::Util::now;

#     my $c = Intern::Bookmark::Context->new;
#     my $dbh = $c->dbh;
#     $dbh->query(q[
#         INSERT INTO bookmark (user_id, entry_id, comment, created, updated)
#           VALUES (?)
#     ], [ $user->user_id, $entry->entry_id, $comment, $created, $updated ]);

#     my $bookmark = Intern::Bookmark::Service::Bookmark->find_bookmark_by_user_and_entry($dbh, {
#         user => $user,
#         entry => $entry
#     });
#     $bookmark->entry($entry);
#     $bookmark->user($user);
#     return $bookmark;
# }

1;
