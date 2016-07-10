package t::Service::Tag;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent qw(Test::Class);

use Test::Diary;
use Test::Mechanize;
use Test::Factory;

use Test::More;
use Test::Deep;
use Test::Exception;

use String::Random qw(random_regex);

use Diary::Context;
use Diary::Service::Tag;

sub _require : Tests(startup) {
    my ($self) = @_;
    require_ok 'Diary::Service::Tag';
}

sub delete : Test(setup) {
    my $c = Diary::Context->new;
    $c->dbh->query(q[ DELETE FROM entry_tag_map ]);
    $c->dbh->query(q[ DELETE FROM tag ]);
}

sub create : Tests {
    my ($self) = @_;
    my $c = Diary::Context->new;

    subtest 'タグ作成できる' => sub {
        my $entry = create_entry;
        Diary::Service::Tag->create($c->dbh, {entry => $entry, tag => 'test1'});
        Diary::Service::Tag->create($c->dbh, {entry => $entry, tag => 'test2'});
        my $tags = Diary::Service::Tag->find_tags_by_entry_id($c->dbh, {entry_id => $entry->entry_id});
        ok $tags;
        is scalar @$tags, 2;
        is $tags->[0]->name, 'test1';
        is $tags->[1]->name, 'test2';
    };
}

__PACKAGE__->runtests;

1;
