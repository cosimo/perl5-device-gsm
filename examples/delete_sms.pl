#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Script that deletes one SMS stored on SIM
#
# $Id: delete_sms.pl,v 1.1 2004-12-03 22:34:11 cosimo Exp $

use strict;
use lib '../lib';
use lib '../';
use Gsm;

print "\nthis is ", '$Id: delete_sms.pl,v 1.1 2004-12-03 22:34:11 cosimo Exp $', "\n";
print "\nDelete specified sms message from SIM card...\n";

my $port = $ENV{'DEV_GSM_PORT'} || ( $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1' );
my $pin  = $ENV{'DEV_GSM_PIN'}  || '0000';
my $baud = $ENV{'DEV_GSM_BAUD'} || 19200;
my $mypin;

unless( $port ) {
	print "Select your serial port [$port] : ";
	chomp( $myport = <STDIN> );
}
$myport ||= $port;

unless( $pin ) {
	print "Insert your PIN number if you need to register to GSM network [$pin] : ";
	chomp( $mypin = <STDIN> );
	$mypin =~ s/\D//g;
	$mypin = substr( $mypin, 0, 4 );
}
$mypin ||= $pin;

my $gsm = new Device::Gsm(
	port => $myport,
	log => 'file,messages.log',
    loglevel => 'debug'
);

die "cannot create Device::Gsm object!" unless $gsm;
die "usage: $0 <msg_index>" unless @ARGV == 1;
print "Connecting on $myport port...";

$gsm->connect( baudrate => $baud ) or die "cannot connect to GSM device on [$myport]\n";

print " ok\n";
print "Registering on GSM network...";

$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print " ok\n";

print "Connected and registered to network.\n";

my $lOk = $gsm->delete_sms($ARGV[0]);

if( $lOk ) {
	print "Ok, message deleted\n";
} else { 
	print "Failed deleting message!\n";
}

$gsm->disconnect();



