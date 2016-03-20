#!/usr/bin/env perl
#
#

use strict;
use Device::Gsm;
use encoding 'utf8';

print "\nthis is send_sms.pl\n";
print "I hope I can send an SMS on your GSM phone attached to...\n";

my $port = $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1';
my $myport;

my $baud = 9600;
my $mybaud;

my $pin = '0000';
my $mypin;

my $mynumber;

if ( exists( $ENV{'GSM_PORT'} ) ) {
    $myport = $ENV{'GSM_PORT'};
    $mypin  = $pin;
}
if ( exists( $ENV{'GSM_BAUD'} ) ) {
    $mybaud = $ENV{'GSM_BAUD'};
    $mypin  = $pin;
}
if ( exists( $ENV{'GSM_PIN'} ) ) {
    $mypin = $ENV{'GSM_PIN'};
}

if ( ( scalar(@ARGV) >= 3 ) && ( scalar(@ARGV) <= 4 ) ) {
    $mynumber = $ARGV[0];
    $myport   = $ARGV[1];
    $mybaud   = $ARGV[2];
    $mypin    = $ARGV[3] || $pin;
}

if ( scalar(@ARGV) == 1 ) {
    $mynumber = $ARGV[0];
}

if ( !defined($myport) ) {
    print "Select your serial port [$port] : ";
    chomp( $myport = <STDIN> );
    $myport ||= $port;
}

if ( !defined($mybaud) ) {
    print "Select your serial baud [9600] : ";
    chomp( $mybaud = <STDIN> );
    $myport ||= 9600;
}

if ( !defined($mypin) ) {
    print
      "Insert your PIN number if you need to register to GSM network [$pin] : ";
    chomp( $mypin = <STDIN> );
    $mypin ||= $pin;
    $mypin =~ s/\D//g;
    $mypin = substr( $mypin, 0, 4 );
}

my $gsm = new Device::Gsm(
    port => $myport,
    pin  => $mypin,
    log  => 'file,send.log'
);

die "cannot create Device::Gsm object!" unless $gsm;

$gsm->connect( baudrate => 9600 )
  or die "cannot connect to GSM device on [$myport]\n";
$gsm->register()
  or die "cannot register on GSM network: check pin and/or network signal!";

print "\nok! connected and registered to network.\n";

if ( !defined($mynumber) ) {
    my $number;
    do {
        print "\nRecipient number (ex.: +490320201020 or 0320201020): ";
        chomp( $number = <STDIN> );
    } until $number;

    $mynumber = $number;
}

my $content = '';
print "\nSMS Text (no max chars, terminate with EOF):\n";
while ( my $line = <STDIN> ) {
    $content .= $line;
}

chomp($content);

my $lOk = $gsm->send_csms(
    content   => $content,
    recipient => $mynumber,
    class     => 'normal'     # try `flash'
);

if ($lOk) {

    print "SMS sent!\n";

} else {

    print "Error in sending!\n";

}

