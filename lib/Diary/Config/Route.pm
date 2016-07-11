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

        connect '/login' => {
            engine => 'Index',
            action => 'login_get',
        } => { method => 'GET' };
        connect '/login' => {
            engine => 'Index',
            action => 'login_post',
        } => { method => 'POST' };

        # connect '/logout' => {
        #      engine => 'Index',
        #      action => 'logout',
        #  };
        connect '/logout' => {
            engine => 'Index',
            action => 'logout_post',
        } => { method => 'POST' };

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

        connect '/user/{username}' => {
            engine => 'User', action => 'default'
        };

        connect '/user/{username}/tags' => {
            engine => 'Tag', action => 'default'
        };

        connect '/user/{username}/tag/{tag}' => {
            engine => 'Tag', action => 'tag'
        };

        # API
        connect '/api/entry/update' => {
            engine => 'API::Entry',
            action => 'update',
        } => { method => 'POST'};

        connect '/api/entry/delete' => {
            engine => 'API::Entry',
            action => 'delete',
        } => { method => 'POST'};
    };
}

1;
