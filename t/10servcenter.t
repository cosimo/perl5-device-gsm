# $Id: 10servcenter.t,v 1.2 2002-04-03 20:59:13 cosimo Exp $
#
# test service center functions 
#
use Test;
BEGIN { plan tests => 4 };
use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0' );

ok( $gsm );
ok( $gsm->connect() );
ok( $gsm->service_center() );

