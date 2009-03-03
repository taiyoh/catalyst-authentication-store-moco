package Catalyst::Authentication::Store::MoCo::User;

use strict;
use warnings;
use base qw/Catalyst::Authentication::User/;
use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config resultset _user _roles/);
}

sub new {
    my ( $class, $config, $c) = @_;

    if (!defined($config->{'user_model'})) {
        $config->{'user_model'} = $config->{'user_class'};
    }

    eval "require $config->{user_model}";
    my $self = {
        resultset => $config->{user_model},
        config => $config,
        _roles => undef,
        _user => undef
    };

    bless $self, $class;

    if (not $self->{'resultset'}) {
        Catalyst::Exception->throw("\$c->model('${ \$self->config->{user_model} }') did not return a resultset. Did you set user_model correctly?");
    }

    ## Note to self- add handling of multiple-column primary keys.
    if (!exists($self->config->{'id_field'})) {
        my @pks = @{ $self->{'resultset'}->primary_keys };
        if ($#pks == 0) {
            $self->config->{'id_field'} = $pks[0];
        } else {
            Catalyst::Exception->throw("user table does not contain a single primary key column - please specify 'id_field' in config!");
        }
    }

    if (!$self->{'resultset'}->has_column($self->config->{'id_field'})) {
        Catalyst::Exception->throw("id_field set to " .  $self->config->{'id_field'} . " but user table has no column by that name!");
    }

    $self->config->{lazyload} = 0;

    return $self;
}

# ユーザを読み込む
sub load {
    my ($self, $authinfo, $c) = @_;

    my $moco_config = 0;

    if (exists($authinfo->{'dbix_class'})) {
        $authinfo = $authinfo->{'dbix_class'};
        $moco_config = 1;
    }

    ## User can provide an arrayref containing the arguments to search on the user class.
    ## or even provide a prepared resultset, allowing maximum flexibility for user retreival.
    ## these options are only available when using the dbix_class authinfo hash. 
    if ($moco_config && exists($authinfo->{'resultset'})) {
        $self->_user($authinfo->{'resultset'}->first);
    } elsif ($moco_config && exists($authinfo->{'searchargs'})) {
        my $users = $self->resultset->retrieve(@{$authinfo->{'searchargs'}});
        if ( ref $users eq 'DBIx::MoCo::List' ) {
            $self->_user( $users->first );
        }
       else {
            $self->_user($users);
        }
    } else {
        ## merge the ignore fields array into a hash - so we can do an easy check while building the query
        my %ignorefields = map { $_ => 1} @{$self->config->{'ignore_fields_in_find'}};
        my $searchargs = {};
        # now we walk all the fields passed in, and build up a search hash.
        foreach my $key (grep {!$ignorefields{$_}} keys %{$authinfo}) {
            if ($self->resultset->has_column($key)) {
                $searchargs->{$key} = $authinfo->{$key};
            }
        }
        if (keys %{$searchargs}) {
            my $u = $self->resultset->retrieve(%$searchargs);
            $self->_user( ( ref $u eq 'DBIx::MoCo::List' )? $u->first : $u );
        } else {
            Catalyst::Exception->throw("User retrieval failed: no columns from " . $self->config->{'user_model'} . " were provided");
        }
    }

    if ($self->get_object) {
        return $self;
    } else {
        return undef;
    }
}

sub supported_features {
    my $self = shift;

    return {
        session         => 1,
        roles           => 1,
    };
}

# これ使ったら絶対に落ちる。なぜなら、使うメソッドはDBICのときのまま…
sub roles {
    my ( $self ) = shift;
    ## this used to load @wantedroles - but that doesn't seem to be used by the roles plugin, so I dropped it.

    ## shortcut if we have already retrieved them
    if (ref $self->_roles eq 'ARRAY') {
        return(@{$self->_roles});
    }

    my @roles = ();
    if (exists($self->config->{'role_column'})) {
        my $role_data = $self->get($self->config->{'role_column'});
        if ($role_data) {
            @roles = split /[\s,\|]+/, $self->get($self->config->{'role_column'});
        }
        $self->_roles(\@roles);
    } elsif (exists($self->config->{'role_relation'})) {
        my $relation = $self->config->{'role_relation'};
        if ($self->_user->$relation->has_column($self->config->{'role_field'})) {
            @roles = map { $_->{$self->config->{'role_field'}} } $self->_user->$relation->search(undef, { columns => [ $self->config->{'role_field'}]})->all();
            $self->_roles(\@roles);
        } else {
            Catalyst::Exception->throw("role table does not have a column called " . $self->config->{'role_field'});
        }
    } else {
        Catalyst::Exception->throw("user->roles accessed, but no role configuration found");
    }

    return @{$self->_roles};
}

# セッションにデータを入れる
sub for_session {
    my $self = shift;

    my %userdata = $self->_user->get_columns();
    return \%userdata;
}

# セッションからのユーザの特定
sub from_session {
    my ($self, $frozenuser, $c) = @_;

    if (exists($self->config->{'use_userdata_from_session'}) && $self->config->{'use_userdata_from_session'} != 0)
    {
        my $obj = $self->resultset->new_result({ %$frozenuser });
        $obj->in_storage(1);
        $self->_user($obj);
        return $self;
    } else {
        my $id;
        if (ref($frozenuser) eq 'HASH') {
            $id = $frozenuser->{$self->config->{'id_field'}};
        } else {
            $id = $frozenuser;
        }
        return $self->load( { $self->config->{'id_field'} => $id }, $c);
    }
}

sub get {
    my ($self, $field) = @_;

    if (defined $self->_user->{$field}) {
        return $self->_user->$field;
    } else {
        return undef;
    }
}

sub get_object {
    my ($self, $force) = @_;

    # $forceが有効の場合、discard_changesするんだけど…
    return $self->_user;
}

sub obj {
    my ($self, $force) = @_;

    return $self->get_object($force);
}

# んなのやるか＞＜
sub auto_create {
    my $self = shift;
    #$self->_user( $self->resultset->auto_create( @_ ) );
    return $self;
}

sub auto_update {
    my $self = shift;
    #$self->_user->auto_update( @_ );
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    $self->_user->$method(@_);
}

1;
