package TestApp::Schema::UserRole;

use strict;
use warnings;
use base 'TestApp::Schema';

__PACKAGE__->table( 'user_role' );
__PACKAGE__->primary_keys( qw/id/ );

__PACKAGE__->has_many( 'roles' => 'TestApp::Schema::Role', { key => { 'roleid' => 'id' }} );

1;
