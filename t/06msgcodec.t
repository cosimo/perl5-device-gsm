# $Id: 06msgcodec.t,v 1.2 2003-09-14 17:47:29 cosimo Exp $
#
# test sim card message encoding/decoding functions 
#
use Test;
BEGIN { plan tests => 10 };
use lib '../lib';
use Device::Gsm; 
ok(1);
use Device::Gsm::Sms;
ok(1);

my @messages = (
	[ '+CMGL: 3,3,,36' => '079193235058580011A50A8123988277790000AD1AC33468FE76BF41B19A0B068381E065F9FCED2E8342A110', 'Ci sono 15.000 persone !!!' ],
	[ '+CMGL: 4,1,,140' => '0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8' ],
	[ '+CMGL: 2,1,,31' => '0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06', 'Aaaabbbaaabbb' ]
);

foreach my $m ( @messages ) {
	print '-' x 72, "\n", "HEADER: $m->[0]\n", "PDU   : $m->[1]\n";
	my $msg = new Device::Gsm::Sms( header => $m->[0], pdu => $m->[1] );
	print 'TEXT  : `', $msg->text(), "'\n";

	if( $m->[2] ) {
		ok( $m->[2], $msg->text(), 'check of decoded message' );
	} else {
		ok( $m->[2], $m->[2], 'missing decoded message text' );
	}
}

