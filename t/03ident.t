# $Id: 03ident.t,v 1.3 2002-04-05 21:29:24 cosimo Exp $
#
# test gsm device identification routines
#
use Test;
BEGIN { plan tests => 8 };
use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0' );

ok( $gsm );

ok( $gsm->connect() );

print 'manufacturer is [', $gsm->manufacturer(), ']', "\n";
print 'device model is [', $gsm->model(),        ']', "\n";
print 'software ver is [', $gsm->software_version(), ']', "\n";
print 'imei code    is [', $gsm->imei(),         ']', "\n";

ok( $gsm->manufacturer ne 'ERROR' );
ok( $gsm->model ne 'ERROR' );
ok( $gsm->software_version ne 'ERROR' );
ok( $gsm->imei, $gsm->serial_number );
ok( $gsm->imei ne 'ERROR' );

