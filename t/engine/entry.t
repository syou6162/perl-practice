package t::Diary::Engine::Entry;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent qw(Test::Class);

use Test::Diary;
use Test::Mechanize qw(create_mech);
use Test::Factory qw(
    create_user create_diary create_entry
);

use Test::More;
use Test::Mock::Guard qw(mock_guard);

use URI;
use URI::QueryParam;

use Diary::Context;
use Diary::Model::User;
use Diary::Service::Diary;
use Diary::Service::Entry;

# sub _default : Tests {
#     my $user = create_user;
#     my $bookmark = create_bookmark(user => $user);

#     my $permalink = URI->new('/bookmark');
#     $permalink->query_param(url => $bookmark->entry->url);

#     my $mech = create_mech(user => $user);
#     $mech->get_ok($permalink);
#     $mech->content_contains(sprintf("%s - %s", $user->name, $bookmark->comment));
# }

sub _add : Tests {
    # my $g = mock_guard 'Diary::Service::Entry', {
    #     fetch_title_by_url => sub { '' },
    # };

    my $c = Diary::Context->new;
    my $user  = create_user;
    my $diary = create_diary(user => $user);
    my $mech = create_mech(user => $user);

    my $title = "タイトル";
    my $content = "ないよー";
    subtest '新規作成' => sub {
        $mech->get_ok('/entry/add');
        $mech->submit_form_ok({
            form_number => 2,
            fields => {
                title     => $title,
                content => $content,
            },
        });
        my $result = Diary::Service::Entry->find_entries_by_user($c->dbh, {
            user  => $user,
            diary => $diary,
        });
        ok $result, 'entry作成されている';
        is $result->[0]->content, $content;
    };

    # subtest '編集' => sub {
    #     my $url = URI->new('/bookmark/add');
    #     $url->query_param(url => $entry->url);

    #     $mech->get_ok($url);
    #     $mech->submit_form_ok({
    #         fields => {
    #             url     => $entry->url,
    #             comment => 'bookmark comment edit'
    #         },
    #     });

    #     my $bookmark = Intern::Bookmark::Service::Bookmark->find_bookmark_by_user_and_entry($c->dbh, {
    #         user  => $user,
    #         entry => $entry,
    #     });
    #     ok $bookmark, 'ブックマーク作成されている';
    #     is $bookmark->comment, 'bookmark comment edit';
    # };
}

# sub _delete : Tests {
#     my $c = Intern::Bookmark::Context->new;

#     my $user  = create_user;
#     my $entry = create_entry;
#     my $bookmark = create_bookmark(user => $user, entry => $entry);

#     my $mech = create_mech(user => $user);

#     my $delete_url = URI->new('/bookmark/delete');
#     $delete_url->query_param(url => $entry->url);

#     $mech->get_ok($delete_url);
#     $mech->submit_form_ok;

#     $bookmark = Intern::Bookmark::Service::Bookmark->find_bookmark_by_user_and_entry($c->dbh, {
#         user  => $user,
#         entry => $entry,
#     });
#     ok !$bookmark, 'ブックマーク消えてる';
# }

__PACKAGE__->runtests;

1;
