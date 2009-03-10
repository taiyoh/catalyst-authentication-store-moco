#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::MoCo' );
}

diag( "Testing Catalyst::Authentication::Store::MoCo $Catalyst::Authentication::Store::MoCo::VERSION, Perl $], $^X" );
