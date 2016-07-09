package Test::Mechanize;

use strict;
use warnings;
use utf8;

use parent qw(Test::WWW::Mechanize::PSGI);
use Plack::Builder;
use Plack::Session;
use HTTP::Cookies;

use Test::More ();

use Exporter qw(import);
our @EXPORT = qw(create_mech);

use Diary;

my $app = builder {
    enable 'HTTPExceptions';

    Diary->as_psgi;
};

sub create_mech (;%) {
    return __PACKAGE__->new(@_);
}

sub new {
    my ($class, %opts) = @_;

    my $user = delete $opts{user};

    my $session_id;
    my $user_mw = sub {
        my $app = shift;
        builder {
            enable 'Session';
            sub {
                my $env = shift;
                my $user_name = $user ? $user->name : '';
                my $session = Plack::Session->new($env);
                $session_id = $session->id;
                $session->set($session_id => $user_name);
                $app->($env);
            };
        };
    };

    my $self = $class->SUPER::new(
        app => $user_mw->($app),
        %opts,
    );

    $self->cookie_jar->set_cookie(
        1,              # version
        $session_id,    # key
        $user->name,    # val
        '/',            # path
        'localhost',    # domain
    );

    return $self;
}

1;
