#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Report signal quality of mobile phone line
#
# $Id: report_signal.pl,v 1.1 2002-09-11 21:06:50 cosimo Exp $

use strict;
use Device::Gsm;

print "\nthis is ", '$Id: report_signal.pl,v 1.1 2002-09-11 21:06:50 cosimo Exp $', "\n";
print "\nGetting signal quality of your mobile phone line...\n\n";

my $port = $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1';
my $myport;

print "Select your serial port [$port] : ";
chomp( $myport = <STDIN> );
$myport ||= $port;

my $gsm = new Device::Gsm( port => $myport, log => 'file,signal.log' );

die "cannot create Device::Gsm object!" unless $gsm;

$gsm->connect( baudrate => 19200 ) or die "cannot connect to GSM device on [$myport]\n";

print "\nok! connected to gsm phone.\n";

my $dBm = $gsm->signal_quality();

if( $dBm ) {

	print "Signal quality reading: $dBm dBm\n";

} else { 

	print "Could not read signal quality!\n";

}



