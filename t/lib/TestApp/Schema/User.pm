package TestApp::Schema::User;

use strict;
use warnings;
use base 'TestApp::Schema';

__PACKAGE__->table( 'user' );
__PACKAGE__->primary_keys( 'id' );

#__PACKAGE__->has_many( 'map_user_role' => 'TestApp::Schema::UserRole', { key => {'user' => 'id' }} );
#__PACKAGE__->many_to_many( roles => 'map_user_role', 'role');

__PACKAGE__->has_many( 'roles' => 'TestApp::Schema::UserRole', { key => { 'id' => 'user' }} );

1;
