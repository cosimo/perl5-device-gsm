# $Id: 20pdu.t,v 1.2 2002-04-09 21:30:10 cosimo Exp $
#
# test pdu encoding functions for sms

use Test;
use Device::Gsm::Pdu;
BEGIN { plan tests => 6 };

# Test encoding mobile numbers
ok( Device::Gsm::Pdu::encode_address('3289287791'),    '0A812398827719'   );
ok( Device::Gsm::Pdu::encode_address('+393289287791'), '0C91932398827719' );
ok( Device::Gsm::Pdu::encode_address('347101010'),     '098143171010F0'   );
ok( Device::Gsm::Pdu::encode_address('+39347101010'),  '0B919343171010F0' );

# Test encoding some text
ok(
	Device::Gsm::Pdu::encode_text7( 'hellohello' ),
	'0AE8329BFD4697D9EC37'
);

ok(
	Device::Gsm::Pdu::encode_text7( 'The quick fox jumps over the lazy dog' ),
	'2554741914AFA7C76B90F98D07A9EB6DF81CF4B697E5203ABA0C6287F57910F97D06'
);

