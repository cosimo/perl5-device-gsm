# $Id: 25msgread.t,v 1.1 2003-03-25 06:51:01 cosimo Exp $
# test pdu messages decoding

use Test;
use lib '../blib/lib';
use Device::Gsm::Sms;

BEGIN { plan tests => 2 };

my $msg = new Device::Gsm::Sms( header => 'xxx', pdu=> 'xxx');
ok( (! defined $msg && ! ref $msg), 1, 'erroneous message (sms object undef)' );

$msg = new Device::Gsm::Sms(header => '', pdu => '');
ok( (! defined $msg && ! ref $msg), 1, 'empty header/pdu message (sms object undef)' );

my @test_data = (
	'+CMGL: 1,1,,99',
	'0791933385280200040C919333393165040000201151314225405B4936082E2FEBF56F101E946683E0631001444E836C3518A85C97BF9',
	'a',
	'+CMGL: 2,1,,31',
	'0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06',
	'a',
	'+CMGL: 4,1,,140',
	'0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8',
	'a',
	'+CMGL: 6,1,,133',
	'0791933385280200040C919333883425580000200150112245408246F9BB0D82CADFF630082A7FDBDF3B05B16C4F8FCBADE3BC0DB2C70',
	'a',
	'+CMGL: 8,1,,106',
	'0791933385280200040C9193335592402700002090424164744063C374F80D2287D9A068BD5C2F839A6177F85C9683A4E5F69BFE0E85C',
	'a',
	'+CMGL: 9,1,,118',
	'0791449737019037040C914497676398780000201121616464007146F9BB0D1286E5EEB0380F82D6E9F4F478BD5310CBF6F4B8DC3ACE1',
	'a',
	'+CMGL: 10,1,,98',
	'0791933385285200040E850093402399810039002001103103044059C334C85E26A7C3ED3728CC669FD2EE70FD5C9787F5E9B7BB0C22F',
	'a'
);

while( @test_data ) {

	$msg = new Device::Gsm::Sms(
		header => shift @test_data,
		pdu    => shift @test_data
	);

	$text = shift @test_data;

	ok( defined $msg && ref $msg eq 'Device::Gsm::Sms', 1, 'sms test-set object' );
	if( $text ) {
		ok( $text, $msg->text, 'check sms text' );
	}

}

# end of messages test
