#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Script that deletes permanently one message from sim
#
# $Id: delete_message.pl,v 1.1 2004-08-18 06:09:53 cosimo Exp $

use strict;
use lib '../lib';
use lib '../';
use Gsm;

print "\nthis is ", '$Id: delete_message.pl,v 1.1 2004-08-18 06:09:53 cosimo Exp $', "\n";
print "\nDeletes one sms message from your sim card...\n";

my $port = $ENV{'DEV_GSM_PORT'} || ( $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1' );
my $myport;

my $pin  = $ENV{'DEV_GSM_PIN'} || '0000';
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

print "Connecting on $myport port...";

$gsm->connect( baudrate => 19200 ) or die "cannot connect to GSM device on [$myport]\n";

print " ok\n";
print "Registering on GSM network...";

$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print " ok\n";

print "Connected and registered to network.\n";

my @msg = $gsm->messages();
my $lOk = scalar @msg;

if( $lOk ) {

	print "You have messages!\n" ;

=cut
	my $n = 0;
	foreach( @msg ) {
		my $sms = $_;
		next unless defined $sms;
		print '-' x 60, "\n", "MESSAGE N. $n\n";
		print 'Type   ',($sms->type() eq Device::Gsm::Sms::SMS_SUBMIT ? 'SUBMIT' : 'DELIVER'), "\n";
		print 'Status ', $sms->status(), "\n";
		print 'From   ', $sms->sender(), "\n";
		print 'To     ', $sms->recipient(), "\n";
		print 'Text   [', $sms->text(), "]\n";
		$n++;
		<STDIN>;
	}
=cut

    my $idx = -1;

    do {
        print "Insert number to be deleted (0-".($#msg)."): ";
        $idx = <STDIN>;
        chomp $idx;
        $idx -= 0;
    } while ( $idx >= 0 && $idx <= $#msg);

    print "Ok, going to delete message [$idx]\n";

    if( $gsm->delete_sms($idx) ) {
        print "Deleted!\n";
    } else {
        print "Error in deletion, Sorry\n";
    }

} else { 

	print "No message on SIM, or error during read!\n";

}




