#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
#
# $Id: send_sms.pl,v 1.1 2002-04-14 09:24:31 cosimo Exp $

use strict;
use Device::Gsm;

print "\nthis is $0 version ", '$Id: send_sms.pl,v 1.1 2002-04-14 09:24:31 cosimo Exp $', "\n";
print "I hope I can send SMS on your GSM phone attached to...\n";

my $port = $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1';
my $myport;

my $pin  = '0000';
my $mypin;

print "Select your serial port [$port] : ";
chomp( $myport = <STDIN> );
$myport ||= $port;

print "Insert your PIN number if you need to register to GSM network [$pin] : ";
chomp( $mypin = <STDIN> );
$mypin ||= $pin;
$mypin =~ s/\D//g;
$mypin = substr( $mypin, 0, 4 );

my $gsm = new Device::Gsm( port => $myport, pin => $mypin, log => 'file,send.log' );

die "cannot create Device::Gsm object!" unless $gsm;

$gsm->connect() or die "cannot connect to GSM device on [$myport]\n";
$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print "\nok! connected and registered to network.\n";

my $number;
do { 
	print "\nRecipient number (ex.: +490320201020 or 0320201020): ";
	chomp( $number = <STDIN> );
} until $number;

my $content;
do { 
	print "\nSMS Text (max 160 chars):\n";
	chomp( $content = <STDIN> );
} until $content;

$content = substr( $content, 0, 160 );

my $lOk = $gsm->send_sms(
	content => $content,
	recipient => $number,
	class     => 'normal'     # try `flash'
);

if( $lOk ) {

	print "SMS sent!\n" ;

} else { 

	print "Error in sending!\n";

}



