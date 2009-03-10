package TestApp::Schema::Role;

use strict;
use warnings;
use base 'TestApp::Schema';

__PACKAGE__->table( 'role' );
__PACKAGE__->primary_keys( 'id' );

__PACKAGE__->has_many( 'users' => 'TestApp::Schema::UserRole', { key => { 'id' => 'roleid' }} );

1;
