# $Id: 20pdu.t,v 1.1 2002-04-09 20:27:24 cosimo Exp $
#
# test pdu creation for sms service
#
use Test;
BEGIN { plan tests => 4 };
use Device::Gsm; 

ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0' );

ok($gsm);

ok( Device::Gsm::Pdu::encodeAddress('3289287791'),    '0A812398827719' );
ok( Device::Gsm::Pdu::encodeAddress('+393289287791'), '0C91932398827719' );

