package OpenID::Lite::Extension::AX::Request;

use Any::Moose;
extends 'OpenID::Lite::Extension::Request';

use OpenID::Lite::Extension::AX qw(
    AX_NS
    AX_NS_ALIAS
    AX_TYPE_NS_OF
);

has 'mode' => (
    is      => 'rw',
    isa     => 'Str',
    default => q{fetch_request},
);

has 'required' => (
    is      => 'rw',
    isa     => 'Str',
    default => q{country,email,firstname,language,lastname},
);

has 'data' => (
    is  => 'rw',
    isa => 'HashRef',
);

override 'append_to_params' => sub {
    my ( $self, $params ) = @_;
    $params->register_extension_namespace( AX_NS_ALIAS, AX_NS );
    $params->set_extension( AX_NS_ALIAS, 'mode',     $self->mode );
    $params->set_extension( AX_NS_ALIAS, 'required', $self->required );

    for my $type ( map {lc} split /\s*,\s*/, $self->required ) {
        next unless exists AX_TYPE_NS_OF->{$type};
        $params->set_extension( AX_NS_ALIAS, "type.${type}",
            AX_TYPE_NS_OF->{$type} );
    }
};

sub add_extension_type {
    my ( $self, $name, $type ) = @_;

    AX_TYPE_NS_OF->{$name} = $type;
}

# for OP side
sub from_provider_response {
    my ( $class, $res ) = @_;
    my $message = $res->params->copy();
    my $ns_url  = AX_NS;
    my $alias   = $message->get_ns_alias($ns_url);
    return unless $alias;
    my $data = $message->get_extension_args($alias) || {};
    my $obj = $class->new( data => _extract_result($message) );
    my $result = $obj->parse_extension_args($data);
    return $result ? $obj : undef;
}

sub _extract_result {
    my ($message) = @_;

    my %params = ();
    for my $ext_name ( keys %{ $message->{_extension_params} } ) {
        for my $key ( keys %{ $message->{_params} } ) {
            if ( my ($new_key) = ( $key =~ /^$ext_name\.value\.(.+)$/ ) ) {
                $params{$new_key} = $message->{_params}->{$key};
            }
        }
    }
    return \%params;
}

sub parse_extension_args {
    my ( $self, $args ) = @_;
    $self->mode( $args->{mode} )         if $args->{mode};
    $self->required( $args->{required} ) if $args->{required};
    return 1;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;

