# $Id: 06msgcodec.t,v 1.4 2004-03-23 22:07:59 cosimo Exp $
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
	[ '+CMGL: 3,3,,36'  => '079193235058580011A50A8123988277790000AD1AC33468FE76BF41B19A0B068381E065F9FCED2E8342A110', 'Ci sono 15.000 persone !!!' ],
	[ '+CMGL: 4,1,,140' => '0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8' ],
	[ '+CMGL: 2,1,,31'  => '0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06', 'Aaaabbbaaabbb' ],
	[ '+CMGL: 1,1,,110' => '059172281991040B917228732143F90000202140311040806846F9BB0D2296EF613619444597E56F3708357DD7E96850D02C4F8FC3A99D8258B6A7C7E5D671DE06D963AE988DA548BBE7F4309B5D2683DE6E1008D59C5ED3EE992CC502C1CB7236C85E73C16036182CA668BEC9BA69B2D82C3AA7' ],
#	[ '+CMGL: 2,2,,22'  => '0791932350585800110000810000AD0FA0D8A61C100C4861F158B6FF2700' => '1<euro><lira><dollaro><yen><paragrafo>abc2<auml>' ]
);

foreach my $m ( @messages ) {
#	print '-' x 72, "\n", "HEADER: $m->[0]\n", "PDU   : $m->[1]\n";
	my $msg = new Device::Gsm::Sms( header => $m->[0], pdu => $m->[1] );
#	print 'TEXT  : `', $msg->text(), "'\n";

	if( $m->[2] ) {
		ok( $m->[2], $msg->text(), 'check of decoded message' );
	} else {
		ok( $m->[2], $m->[2], 'missing decoded message text' );
	}
}

