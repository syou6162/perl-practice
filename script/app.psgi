use strict;
use warnings;
use utf8;

use lib 'lib';

use Diary;
use Diary::Config;

use Path::Class qw(file);
use Plack::Builder;

my $app = Diary->as_psgi;
my $root = config->root;

builder {
    enable 'Runtime';
    enable 'Head';

    # static file

    enable 'Static', (
        path => qr<^/(?:images|js|css)/>,
        root => config->param('dir.static.root'),
    );
    enable 'Static', (
        path => qr<^/favicon\.ico$>,
        root => config->param('dir.static.favicon'),
    );

    # access and error logs

    my $log = +{ map {
        my $file = file($ENV{uc "${_}_log"} || config->param("file.log.${_}"));
        $file->dir->mkpath;
        my $fh = $file->open('>>') or die "Cannot open >> $file: $!";
        $fh->autoflush(1);
        $_ => $fh;
    } qw(access error) };

    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{'psgi.errors'} = $log->{error};
            return $app->($env);
        };
    };

    enable 'AccessLog::Timed', (
        logger => sub {
            my $fh = $log->{access};
            print $fh @_;
        },
        format => join(
            "\t",
            'time:%t',
            'host:%h',
            'domain:%V',
            'req:%r',
            'status:%>s',
            'size:%b',
            'referer:%{Referer}i',
            'ua:%{User-Agent}i',
            'taken:%D',
            'xdispatch:%{X-Dispatch}o',
        )
    );

    enable 'HTTPExceptions';

    # session and login

    require Plack::Session::State::Cookie;
    require Plack::Session::Store::DBI;
    my $dbh  = DBI->connect( 'dbi:mysql:dbname=perl_practice_diary;host=localhost', 'nobody', 'nobody' );
    enable 'Session',
        store => Plack::Session::Store::DBI->new( dbh => $dbh ),
        state => Plack::Session::State::Cookie->new( session_key => 'sid' );

    $app;
};
