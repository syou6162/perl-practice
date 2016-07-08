#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

use Encode qw/encode_utf8 decode_utf8/;
use JSON;
use DateTime::Format::Strptime;
use Diary::Service::User;
use Diary::Service::Diary;
use Diary::Service::Entry;
use Diary::Context;
use Diary::Config;

my $strp = DateTime::Format::Strptime->new(
    pattern  => '%Y-%m-%d %H:%M:%S +0900',
);

sub flatten_message {
    my $message = shift;
    my $dt = $strp->parse_datetime($message->{time}->[0]);
    my $result = {
        list => $message->{list}->[0],
        date => $dt,
        user => $message->{user}->[0],
        text => $message->{text}->[0],
    };
    $result;
}

sub read_json_file {
    my $filename = shift;
    my $json = JSON->new;
    my $json_text = do {
        open(my $json_fh, "<:encoding(UTF-8)", $filename)
            or die("Can't open \$filename\": $!\n");
        local $/;
        <$json_fh>;
    };
    $json->decode($json_text);
}

BEGIN { $ENV{INTERN_BOOKMARK_ENV} = 'local' };
my $context = Diary::Context->from_env(config);

my $filename = "/Users/yasuhisa/Dropbox/jsons/tweets.json";
my $messages = read_json_file $filename;
foreach my $msg (@$messages) {
    eval { # duplicateで怒られるときがあるけど、無視する
        my $msg = flatten_message $msg;
        my $date = $msg->{date};
        my $username = $msg->{user};
        my $text = $msg->{text};
        my $created = $msg->{date};
        next unless $username && $text;
        my $result = encode_utf8 "@" . $username . ": " . $text . " (" . $date . ")";
        print $result, "\n";
        my $user = Diary::Service::User->find_or_create_user_by_name( $context->dbh, { name => $username } );
        my $diary = Diary::Service::Diary->find_or_create_diary_by_user( $context->dbh, { user => $user } );
        my $hash = {
            user    => $user,
            diary   => $diary,
            created => $created,
            title   => $username,
            content => $text,
        };
        Diary::Service::Entry->create( $context->dbh, $hash );
    }
}
