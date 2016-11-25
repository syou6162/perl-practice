use strict;
use warnings;
use v5.10;

use Storable;
use Net::Google::Spreadsheets;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::OAuth2::AccessToken;
use HTML::ExtractContent;
use Term::Prompt;
use LWP::Simple;
use JSON::XS;
use JSON::Types;

use utf8;
use Encode;

# https://jordanlabs.net/blog/2015/11/19/reusing-google-oauth2-access-tokens-in-perl/
# https://docs.google.com/spreadsheets/d/1hns21olaGaHApaPUDUOwrxVJWotxNDNzBs3euIrp1-Y/edit#gid=0

sub store_session_info {
    my ($client_id, $client_secret, $session_file) = @_;
    my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => $client_id,
        client_secret => $client_secret,
        scope => ['http://spreadsheets.google.com/feeds/'],
    );
    my $url = $oauth2->authorize_url();

    print "URL: $url\n";

    my $code = prompt('x', 'paste the code: ', '', '');

    my $token = $oauth2->get_access_token($code) or die;
    my $session = $token->session_freeze;

    # save the session which can be restored later
    store($session, $session_file);
}

sub download_csv {
    my ($client_id, $client_secret, $session_file) = @_;

    my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => $client_id,
        client_secret => $client_secret,
        scope => [ 'http://spreadsheets.google.com/feeds/' ],
    );

    # deserialise the file so we can thaw the session and reuse the refresh token
    my $session = retrieve($session_file);
    my $extractor = HTML::ExtractContent->new;

    my $restored_token = Net::OAuth2::AccessToken->session_thaw(
        $session,
        auto_refresh => 1,
        profile => $oauth2->oauth2_webserver,
    );
    $oauth2->access_token($restored_token);

    my $service = Net::Google::Spreadsheets->new(
        auth => $oauth2,
    );

    my $spreadsheet = $service->spreadsheet( { title => 'suggest-entries-for-ml-study' } );
    my $worksheet = $spreadsheet->worksheet( { title => 'Sheet1' } );

    my @rows = $worksheet->rows({ });
    for (my $idx = 0; $idx < scalar @rows; $idx++) {
        my $result = $rows[$idx];
        my $url = $result->param('url');
        my $label = $result->param('label') || 0;
        if ( $result->param('title') || $result->param('content') ) {
            say JSON::XS::encode_json(
                {
                    url     => JSON::Types::string $url,
                    label   => JSON::Types::number $label,
                    title   => JSON::Types::string $result->param('title'),
                    content => JSON::Types::string $result->param('content'),
                }
            );
            next;
        }
        my $html = get($url);
        my $title;
        my $content;
        if ($html && $html =~ m{<TITLE>(.*?)</TITLE>}gism) {
            $title = $1;
            $title =~ s/\n/ /g;
            eval {
                # "An invalid XML character was found in the element content of the document"でspreadsheetに設定できないときがある
                $result->param( { 'title' => $title } ) unless $result->param('title');

                $extractor->extract($html);
                $content = encode_utf8 $extractor->as_text;
                $result->param( { 'content' => $content } ) unless $result->param('content');
            }
        } else {
            $title = "NO_TITLE";
            $result->param( { 'title' => $title } )
        }
        say JSON::XS::encode_json(
            {
                url     => JSON::Types::string $url,
                label   => JSON::Types::number $label,
                title   => JSON::Types::string $title,
                content => JSON::Types::string $content,
            }
        );
        say encode_utf8 $url . ", " . $label . ", " . "$title";
    }

    # my $max_row = 1000;
    # my @cells = $worksheet->cells({
    #     'min-row' => 1,
    #     'max-row' => $max_row,
    #     'min-col' => 1,
    #     'max-col' => 2
    # });

    # for (my $idx = 0; $idx < $max_row; $idx++) {
    #     my $n = $idx * 2;
    #     my $url = $cells[$n] && $cells[$n]->content;
    #     my $label = ($cells[$n + 1] && $cells[$n + 1]->content) || 0;
    #     # my $title = ($cells[$n + 2] && $cells[$n + 2]->content) || "";
    #     my $html = get($url);
    #     if ($html && $html =~ m{<TITLE>(.*?)</TITLE>}gism) {
    #         my $tmp = $1;
    #         $tmp =~ s/\n/ /g;
    #         say encode_utf8 $url . ", " . $label . ", " . "$tmp";
    #     }
    # }
}

my $client_id = $ENV{GOOGLE_OAUTH_CLIENT_ID};
my $client_secret = $ENV{GOOGLE_OAUTH_CLIENT_SECRET};
my $session_file = "google_spreadsheet.session";

# store_session_info($client_id, $client_secret, $session_file);
download_csv($client_id, $client_secret, $session_file);
