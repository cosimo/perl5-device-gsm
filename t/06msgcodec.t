# $Id: 06msgcodec.t,v 1.8 2006-08-12 08:57:19 cosimo Exp $
#
# test sim card message encoding/decoding functions 
#

use strict;
use warnings;

use Test::More;
use lib '../lib';

BEGIN { plan tests => 9 };

use_ok('Device::Gsm');
use_ok('Device::Gsm::Sms');
use_ok('Device::Gsm::Pdu');

my @messages = (
	[ '+CMGL: 3,3,,36'  => '079193235058580011A50A8123988277790000AD1AC33468FE76BF41B19A0B068381E065F9FCED2E8342A110', 'Ci sono 15.000 persone !!!' ],

	[ '+CMGL: 4,1,,140' => '0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8' ],

	[ '+CMGL: 2,1,,31'  => '0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06', 'Aaaabbbaaabbb' ],

	[ '+CMGL: 1,1,,110' => '059172281991040B917228732143F90000202140311040806846F9BB0D2296EF613619444597E56F3708357DD7E96850D02C4F8FC3A99D8258B6A7C7E5D671DE06D963AE988DA548BBE7F4309B5D2683DE6E1008D59C5ED3EE992CC502C1CB7236C85E73C16036182CA668BEC9BA69B2D82C3AA7' ],

#	[ '+CMGL: 2,2,,22'  => '0791932350585800110000810000AD0FA0D8A61C100C4861F158B6FF2700' => '1<euro><lira><dollaro><yen><paragrafo>abc2<auml>' ],

    [ '+CMGL: 0,0,,00'  => '07919471016730510410D06B7658DE7E8BD36C39006070228105118094C8309BFD6681C262D0FC6D7ECBE92071DA0D4A8FD1A0BA9B5E9683DCE57A590E92D6CDEE7ABB5D968356B45CAC16ABD972319A8C360395E5F2727A8C1687E52E90355D66974147B9DF530651DFF239BDEC0635FD6C7659EE5296E97A3A68CD0ECBC7613919242ECFE96536BBEC06D5DDF4B21C74BFDF5D6B7658DE7E8BD36C17B90C', "Hallo, ab sofort bin ich unter neuer Rufnummer +4915156914243 erreichbar. Viele Gr\xFC\xDFe Torsten M\xFCller.Jetzt klarcard bestellen unter www.klarmobil.de" ],

	# Test for outgoing message decoding
	[ '+CMGL: 5,3,,35'  => '0011FF048160110000AD1CD4F29C0E6A97E7F3F0B90C32BFE52062D99E1E9775BAE3BC0D', 'Test message for Device::Gsm']
);

foreach my $m ( @messages ) {
	#diag('-' x 72, "\n", "Header: $m->[0]\n", "PDU   : $m->[1]\n");
	my $msg = new Device::Gsm::Sms( header => $m->[0], pdu => $m->[1] );
    #diag('Sender `', $msg->sender(), '\'');
    #diag('Text   `', $msg->text(), '\'');
	if( $m->[2] ) {
		is( $m->[2], $msg->text(), 'check of decoded message' );
	} else {
		is( $m->[2], $m->[2], 'missing decoded message text' );
	}
}

