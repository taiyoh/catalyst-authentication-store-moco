package TestApp::Schema;

# Created by DBIx::Class::Schema::Loader v0.03007 @ 2006-10-18 12:38:33

use strict;
use warnings;

use base 'DBIx::MoCo';

__PACKAGE__->db_object('TestApp::Schema::DataBase');

package TestApp::Schema::DataBase;

use base qw/DBIx::MoCo::DataBase/;

our $db_file = $ENV{TESTAPP_DB_FILE} || '';

__PACKAGE__->dsn("dbi:SQLite:$db_file");
__PACKAGE__->username('');
__PACKAGE__->password('');

#$DBIx::MoCo::DataBase::DEBUG = 1;

1;
