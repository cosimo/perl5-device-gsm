# $Id: 03ident.t,v 1.1 2002-04-03 20:54:09 cosimo Exp $
#
# test connection with a gsm device on serial port
#
use Test;
BEGIN { plan tests => 4 };
use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0' );

ok($gsm);

ok($gsm->connect());

print 'manufacturer is [', $gsm->manufacturer(), ']', "\n";
print 'device model is [', $gsm->model(),        ']', "\n";
print 'software ver is [', $gsm->software_version(), ']', "\n";

ok( $gsm->manufacturer && $gsm->model() && $gsm->software_version() );

