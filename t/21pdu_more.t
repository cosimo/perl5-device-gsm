# test pdu encoding/decoding functions, specifically for CUSD responses from german eplus network

use encoding 'latin1';
use Test::More;
use Device::Gsm::Pdu;
use Device::Gsm::Charset;

BEGIN { plan tests => 2 };

# PDU without length...
my $pdu = 'D37419840E8BCB6E10B92CD797D374D0BA9C7697414F383DFD7683CE65717D8CA6BB40DA7A1B544CBBE5E9319A5E7683CA6977590E7AC2E9E9B71B74DFA3D96537689A2E83C4693ABD0C2297DDA066D9ED87D7DD6B3A485C1FA3CB6E17';

my $plain = 'Sie haben derzeit keine Option gebucht. Zum Einrichten einer Option wählen Sie bitte den Menüpunkt buchen.';

sub from_pdu
{
	# Reattach a length octet.
	my $s = shift;
	my $l = uc(hex(length($s)/2));
	if(length($l) < 2){ $l = '0'.$l; }
	return
	Device::Gsm::Charset::gsm0338_to_iso8859( Device::Gsm::Pdu::decode_text7($l.$s) );
}

sub to_pdu
{
	my $fullpdu = Device::Gsm::Pdu::encode_text7( Device::Gsm::Charset::iso8859_to_gsm0338($_[0]) );
	return substr($fullpdu, 2); # strip off the length octet
}

# Test en- and decoding of that message.

is( from_pdu($pdu), $plain); #1
is( to_pdu($plain),  $pdu);  #2

# end of pdu library test
