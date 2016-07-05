package Diary::Config::Route;

use strict;
use warnings;
use utf8;

use Diary::Config::Route::Declare;

sub make_router {
    return router {
        connect '/' => {
            engine => 'Index',
            action => 'default',
        };

        connect '/entry' => {
            engine => 'Entry',
            action => 'default',
        };

        connect '/entry/add' => {
            engine => 'Entry',
            action => 'add_get',
        } => { method => 'GET' };
        connect '/entry/add' => {
            engine => 'Entry',
            action => 'add_post',
        } => { method => 'POST' };

        connect '/entry/delete' => {
            engine => 'Entry',
            action => 'delete_get',
        } => { method => 'GET' };
        connect '/entry/delete' => {
            engine => 'Entry',
            action => 'delete_post',
        } => { method => 'POST' };

        # API
        connect '/api/entries' => {
            engine => 'API',
            action => 'entries',
        };
        connect '/api/entry' => {
            engine => 'API',
            action => 'entry_post',
        } => { method => 'POST'};
    };
}

1;
