package Catalyst::Authentication::Store::MoCo;
# ported from Catalyst::Authentication::Store::DBIx::Class

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION= "0.0001_1";

BEGIN {
    __PACKAGE__->mk_accessors(qw/config/);
}

sub new {
    my ( $class, $config, $app ) = @_;

    ## figure out if we are overriding the default store user class 
    $config->{'store_user_class'} = (exists($config->{'store_user_class'})) ? $config->{'store_user_class'} :
                                        "Catalyst::Authentication::Store::MoCo::User";

    ## make sure the store class is loaded.
    Catalyst::Utils::ensure_class_loaded( $config->{'store_user_class'} );

    ## fields can be specified to be ignored during user location.  This allows
    ## the store to ignore certain fields in the authinfo hash.

    $config->{'ignore_fields_in_find'} ||= [ ];

    my $self = {
                    config => $config
               };

    bless $self, $class;

}

# セッションからのユーザの特定
sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

    my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
    return $user->from_session($frozenuser, $c);
}

# セッションにデータを入れる
sub for_session {
    my ($self, $c, $user) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);

    return $user->load($authinfo, $c);

}

sub user_supports {
    my $self = shift;
    # this can work as a class method on the user class
    $self->config->{'store_user_class'}->supports( @_ );
}

sub auto_create_user {
    my( $self, $authinfo, $c ) = @_;
    my $res = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
    return $res->auto_create( $authinfo, $c );
}

sub auto_update_user {
    my( $self, $authinfo, $c, $res ) = @_;
    $res->auto_update( $authinfo, $c );
    return $res;
}

1;

