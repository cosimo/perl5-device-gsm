#!/usr/bin/perl
#
# This example sends an SMS to cosimo@cpan.org, the author
# of Device::Gsm module.
#
# This is a funny experiment to know how many people are
# using this module out there... :-) 
#
# $Id: send_to_cosimo.pl,v 1.4 2005-08-27 12:40:13 cosimo Exp $

use strict;
use Config;
use Device::Gsm;

print "\nthis is ", '$Id: send_to_cosimo.pl,v 1.4 2005-08-27 12:40:13 cosimo Exp $', "\n\n";
print "\n", '-' x 80, "\n";
print "HEY! I'm sending out an SMS message to the author of Device::Gsm module\n";
print "(Cosimo Streppone <cosimo\@cpan.org>).\n\n";

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
$gsm->connect( baudrate => 9600 ) or die "cannot connect to GSM device on [$myport]\n";
$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print "\nOk, now ready to send.\n";

print "Your name? ";
my $name = <STDIN>;
chomp $name;

print "Insert your comment for me...: ";
my $comment = <STDIN>;
chomp $comment;

#
# My GSM phone number
# 
my $number = '+393289287791';
my $content =
	'From '.$name.";\n".
	'Device-Gsm v'.$Device::Gsm::VERSION.','."\n".
	'on '.$Config{'myhostname'}.$Config{'mydomain'}.' ('.$Config{'myarchname'}.'), perl v'.$]."\n".
	'Mod:' . ($gsm->manufacturer() || '').'/'.($gsm->model() || '').
	' Ver:'. ($gsm->software_version()||''). "\n" .
	"-- ".$comment;

$content = substr( $content, 0, 160 );

print "Text of the message being sent (max 160 chars)...:\n", $content, "\n";

my $lOk = $gsm->send_sms(
	content   => $content,
	recipient => $number,
	class     => 'normal'
);

if( $lOk ) {
	print "\nThank you for your kind intentions!\n";
} else { 
	print "\nError in sending!\n";
}

