# $Id: 30register.t,v 1.1 2002-04-08 22:09:00 cosimo Exp $
#
# test network registration (pid must be supplied) 
#
use Test;
BEGIN { plan tests => 3 };

use Device::Gsm; 

ok 1;

$pin =~ s/\D//g;
my $gsm = new Device::Gsm( pin => $pin, port => '/dev/ttyS0' );

ok $gsm;

if( $gsm ) {
	print "Insert your PIN number: "; chomp ( $pin = <STDIN> );
	ok $gsm->register();
}


