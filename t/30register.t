# $Id: 30register.t,v 1.2 2002-04-29 17:01:16 cosimo Exp $ #
# test network registration (pid must be supplied) 
#
use Test;
BEGIN { plan tests => 3 };

use Device::Gsm; 

ok 1;

# Here you should set your SIM PIN to make this test
# work as expected!
#
# Ex.: $pin = '0591';
$pin = '';

$pin and $pin =~ s/\D//g;
my $gsm = new Device::Gsm( pin => $pin, port => '/dev/ttyS0' );

ok $gsm;

if( $gsm ) {
	if( $pin ne '' ) {
		ok( $gsm->register() );
	} else {
		skip('Set your SIM PIN in [t/30register.t] to enable!', $gsm->register() ); 
	}
}

