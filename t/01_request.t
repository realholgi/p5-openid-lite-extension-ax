use strict;
use Test::More tests => 3;


use OpenID::Lite::RelyingParty::CheckID::Request;
use OpenID::Lite::RelyingParty::Discover::Service;
use OpenID::Lite::Association;
use OpenID::Lite::Extension::AX::Request;
use OpenID::Lite::Extension::AX::Response;
use OpenID::Lite::Provider::Response;
use OpenID::Lite::Provider::AssociationBuilder;
use URI::Escape;
use URI; 

my $service = OpenID::Lite::RelyingParty::Discover::Service->new;
$service->claimed_identifier( q{http://localhost/openid/user} );
$service->op_local_identifier( q{http://localhost/openid/user} );
$service->add_type( q{http://specs.openid.net/auth/2.0/signon} );
$service->add_uri( q{http://localhost/openid/endpoint} );

my $assoc = OpenID::Lite::Association->new(
    expires_in => 1209600,
    handle     => "1246414277:HMAC-SHA1:49NIG8sn99Tc2fp0QNuZ:d60c3afc89",
    issued     => 1246413115,
    secret     => pack("H*","9c1537e999f93fa31f17346c2f620aaf0518bc0d"),
    type       => "HMAC-SHA1",
);

my $checkid = OpenID::Lite::RelyingParty::CheckID::Request->new(
    association => $assoc,
    service     => $service,
);

my $ax = OpenID::Lite::Extension::AX::Request->new;
$ax->add_extension_type('partnerdata', q{http://axschema.org/unitedinternet/partnerdata}); 
$ax->required(q{firstname,lastname,email,partnerdata});

$checkid->add_extension( $ax );

my $url = $checkid->redirect_url(
    return_to => q{http://example.com/return_to},
    realm     => q{http://example.com/},
);
my $query = URI->new($url)->query;
my %p;
for my $pair ( split /&/, $query ) {
    my ($k, $v) = split(/=/, $pair);
    $k = URI::Escape::uri_unescape($k);
    $v = URI::Escape::uri_unescape($v);
    $p{$k} = $v;
}
is($p{'openid.ax.required'}, 'firstname,lastname,email,partnerdata');
is($p{'openid.ax.type.firstname'}, q{http://axschema.org/namePerson/first});
is($p{'openid.ax.type.partnerdata'}, q{http://axschema.org/unitedinternet/partnerdata});

