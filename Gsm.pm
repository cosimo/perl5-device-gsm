# Device::Gsm - a Perl class to interface GSM devices as AT modems
# Copyright (C) 2002 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for more details.
#
# Additionally, this is now ALPHA software, still needs extensive
# testing and support for custom GSM commands, so use it at your own risk,
# and without ANY warranty! Have fun.
#
# $Id: Gsm.pm,v 1.13 2002-04-24 18:56:05 cosimo Exp $

package Device::Gsm;
$Device::Gsm::VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;

use strict;
use Device::Modem;
use Device::Gsm::Pdu;

@Device::Gsm::ISA = ('Device::Modem');

# Connection defaults to 19200 baud. This seems to be the optimal
# rate for serial links to new gsm phones.
$Device::Gsm::BAUDRATE = 19200;

# Time to wait after network register command (secs)
$Device::Gsm::REGISTER_DELAY = 2;


# Connect on serial port to gsm device
# see parameters on Device::Modem::connect()
sub connect {
	my $me = shift;
	my %aOpt;
	%aOpt = @_ if(@_);

	#
	# If you have problems with bad characters being trasmitted across serial link,
	# try different baud rates, as below...
	#
	# .---------------------------------.
	# | Model (phone/modem) |  Baudrate |
	# |---------------------+-----------|
	# | Falcom Swing (A2D)  |      9600 |
	# | Siemens C35/C45     |     19200 |
	# | Nokia phones        |     19200 |
	# | Digicom             |      9600 |
	# | Nokia Communicator  |      9600 |
	# `---------------------------------'
	#
	# GSM class defaults to 19200 baud
	#
	$aOpt{'baudrate'} ||= $Device::Gsm::BAUDRATE;

	$me->SUPER::connect( %aOpt );
}

# Hangup and terminate active call(s)
# this overrides the `Device::Modem::hangup()' method
sub hangup {
	my $self = shift;
	$self->log->write('info', 'hanging up...');
	$self->attention();
	$self->atsend( 'AT+CHUP' . Device::Modem::CR );
	$self->flag('OFFHOOK', 0);
	$self->answer();
}

# Who is the manufacturer of this device?
sub manufacturer() {
	my $self = shift;
	my($ok, $man);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMI') ) {

		$self->atsend( 'AT+CGMI' . Device::Modem::CR );
		($ok, $man) = $self->parse_answer();

		$self->log->write('info', 'manufacturer of this device appears to be ['.$man.']');

	}

	return $ok eq 'OK' ? $man : $ok;

}

# What is the model of this device?
sub model() {
	my $self = shift;
	my($code, $model);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMM') ) {

		$self->atsend( 'AT+CGMM' . Device::Modem::CR );
		($code, $model) = $self->parse_answer();

		$self->log->write('info', 'model of this device is ['.$model.']');

	}

	return $code eq 'OK' ? $model : $code;
}

# Get handphone serial number (IMEI number)
sub imei() {
	my $self = shift;
	my($code,$imei);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGSN') ) {

		$self->atsend( 'AT+CGSN' . Device::Modem::CR );
		($code, $imei) = $self->parse_answer();

		$self->log->write('info', 'IMEI code is ['.$imei.']');

	}

	return $code eq 'OK' ? $imei : $code;
}

# Alias for `imei()' is `serial_number()'
*serial_number = *imei;


# Get the GSM software version on this device
sub software_version() {
	my $self = shift;
	my($code, $ver);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMR') ) {

		$self->atsend( 'AT+CGMR' . Device::Modem::CR );
		($code, $ver) = $self->parse_answer();

		$self->log->write('info', 'GSM version is ['.$ver.']');

	}

	return $code eq 'OK' ? $ver : $code;
}


sub test_command {
	my($self, $command) = @_;

	# Standard test procedure for every command
	$self->log->write('info', 'testing support for command ['.$command.']');
	$self->atsend( "AT+$command=?" . Device::Modem::CR );

	# If answer is ok, command is supported
	my $ok = $self->answer() =~ /OK/;
	$self->log->write('info', 'command ['.$command.'] is '.($ok ? '' : 'not ').'supported');

	$ok;
}

# register to GSM service provider network
sub register {
	my $me = shift;
	my $lOk = 0;
	
	# Check for connection
	if( ! $me->{'CONNECTED'} ) {
		$me->log-> write( 'info', 'Not yet connected. Doing it now...' );
		if( ! $me->connect() ) {
			$me->log->write( 'warning', 'No connection!' );
			return $lOk
		}
	}

	# Send PIN status query
	$me->log->write( 'info', 'PIN status query' );
	$me->atsend( 'AT+CPIN?' . Device::Modem::CR );
	
	# Get answer
	my $cReply = $me->answer();

	if( $cReply =~ /READY/ ) {
		
		$me->log->write( 'info', 'Already registered on network. Ready to send.' );
		$lOk = 1;
		
	} elsif( $cReply =~ /SIM PIN/ ) {
		
		# Pin request, sending PIN code
		$me->log->write( 'info', 'PIN requested: sending...' );
		$me->atsend( qq[AT+CPIN="$$me{'pin'}"] . Device::Modem::CR );
		
		# Get reply
		$cReply = $me->answer();

		# Test reply		
		if( $cReply !~ /ERROR/ ) {
			$me->log->write( 'info', 'PIN accepted. Ready to send.' );
			$lOk = 1;
		} else {
			$me->log->write( 'warning', 'PIN rejected' );
			$lOk = 0;
		}

	}

	# Store status in object and return
	$me->{'REGISTERED'} = $lOk;

	$lOk;

	# XXX Sending number of service provider
	# $me->log -> write( 'Sending service provider number' );
	
}


# send_sms( %options )
#
#	recipient => '+39338101010'
#	class     => 'flash' | 'normal'
#   validity  => [ default = 4 days ]
#   content   => 'text-only for now'
#   mode      => 'text' | 'pdu'        (default = 'pdu')
# 
sub send_sms {

	my( $me, %opt ) = @_;

	my $lOk = 0;

	return unless $opt{'recipient'} and $opt{'content'};

	# Check if registered to network
	if( ! $me->{'REGISTERED'} ) {
		$me->log->write( 'info', 'Not yet registered, doing now...' );
		$me->register();

		# Wait some time to allow SIM registering to network
		$me->wait( $Device::Gsm::REGISTER_DELAY << 10 );
	}

	# Again check if now registered
	if( ! $me->{'REGISTERED'} ) {
		
		$me->log->write( 'warning', 'ERROR in registering to network' );
		return $lOk;
		
	}

	# Ok, registered. Select mode to send SMS
	$opt{'mode'} ||= 'PDU';
	if( uc $opt{'mode'} ne 'TEXT' ) {

		$lOk = $me->_send_sms_pdu( %opt );

	} else {

		$lOk = $me->_send_sms_text( %opt );
	}

	# Return result of sending
	return $lOk;
}


# _send_sms_text( %options ) : sends message in text mode
sub _send_sms_text {
	my($me, %opt) = @_;

	my $num  = $opt{'recipient'};
	my $text = $opt{'content'};

	return 0 unless $num and $text;

	my $lOk = 0;
	my $cReply;

	# Select text format for messages
	$me->atsend(  q[AT+CMGF=1] . Device::Modem::CR );
	$me->wait(200);
	$me->log_>write('info', 'Selected text format for message sending');

	# Send sms in text mode
	$me->atsend( qq[AT+CMGS="$num"] . Device::Modem::CR );
	$me->wait(200);

	$me->atsend( $text . Device::Modem::CTRL_Z );
	$me->wait(1000);

	# Get reply and check for errors
	$cReply = $me->answer();
	if( $cReply =~ /ERROR/i ) {
		$me->log->write( 'warning', "ERROR in sending SMS" );
	} else {
		$me->log->write( 'info', "Sent SMS (text mode) to $num!" );
		$lOk = 1;
	}
	
	$lOk
}


sub _send_sms_pdu {
	my($me, %opt) = @_;

	# Get options
	my $num =  $opt{'recipient'};
	my $text = $opt{'content'};

	return 0 unless $num and $text;

	# Select class of sms (normal or *flash sms*)
	my $class = $opt{'class'} || 'normal';
	$class = $class eq 'normal' ? '00' : 'F0';

	# TODO Validity period (now fixed to 4 days)
	my $vp = 'AA';

	my $lOk = 0;
	my $cReply;

	# Send sms in PDU mode

	#
	# Example of sms send in PDU mode
	#
	#AT+CMGS=22
	#> 0011000A8123988277190000AA0AE8329BFD4697D9EC37
	#+CMGS: 111
	#
	#OK

	# Encode DA
	my $enc_da = Device::Gsm::Pdu::encode_address( $num );
	$me->log->write('info', 'encoded dest. address is ['.$enc_da.']');

	# Encode text
	my $enc_msg = Device::Gsm::Pdu::encode_text7( $text );
	$me->log->write('info', 'encoded 7bit text (w/length) is ['.$enc_msg.']');

	# Build PDU data
	my $pdu = uc join( '', '00', '11', '00', $enc_da, '00', $class, $vp, $enc_msg );

	$me->log->write('info', 'due to send PDU ['.$pdu.']');

	# Sending main SMS command ( with length )
	my $len = ( (length $pdu) >> 1 ) - 1; 
	#$me->log->write('info', 'AT+CMGS='.$len.' string sent');

	# Select PDU format for messages
	$me->atsend(  q[AT+CMGF=0] . Device::Modem::CR );
	$me->wait(200);
	$me->log_>write('info', 'Selected PDU format for msg sending');

	# Send SMS length
	$me->atsend( qq[AT+CMGS=$len] . Device::Modem::CR );
	$me->wait(200);

	# Sending SMS content encoded as PDU	
	$me->log->write('info', 'PDU sent ['.$pdu.' + CTRLZ]' );
	$me->atsend( $pdu . Device::Modem::CTRL_Z );
	$me->wait(2000);

	# Get reply and check for errors
	$cReply = $me->answer();

	if( $cReply =~ /ERROR/i ) {
		$me->log->write( 'warning', "ERROR in sending SMS" );
	} else {
		$me->log->write( 'info', "Sent SMS (pdu mode) to $num!" );
		$lOk = 1;
	}
	
	$lOk
}


#
# Set or request service center number
#
sub service_center(;$) {

	my $self = shift;
	my $nCenter;
	my $lOk = 1;
	my $code;

	# If additional parameter is supplied, store new message center number
	if( @_ ) {
		$nCenter = shift();

		# Remove all non numbers or `+' sign
		$nCenter =~ s/[^0-9+]//g;

		# Send AT command
		$self->atsend( qq[AT+CSCA="$nCenter"] . Device::Modem::CR );

		# Check for modem answer
		$lOk = ( $self->answer =~ /OK/ );
		
		if( $lOk ) {
			$self->log->write('info', 'service center number ['.$nCenter.'] stored');
		} else {
			$self->log->write('warning', 'unexpected response for "service_center" command');
		}

	} else {

		$self->log->write('info', 'requesting service center number');
		$self->atsend('AT+CSCA?' . Device::Modem::CR );

		# Get answer and check for errors
		($code, $nCenter) = $self->parse_answer();

		if( $code =~ /ERROR/ ) {
			$self->log->write('warning', 'error status for "service_center" command');
			$lOk = 0;
		} else {
			# $nCenter =~ tr/\r\nA-Z//s;
			$self->log->write('info', 'service center number is ['.$nCenter.']');

			# Return service center number
			$lOk = $nCenter;
		}

	}

	# Status flag or service center number
	return $lOk;

}


2703;




__END__

=head1 NAME

Device::Gsm - Perl extension to interface GSM cellular / modems

=head1 WARNING

   This is C<PRE-ALPHA> software, still needs extensive testing and
   support for custom GSM commands, so use it at your own risk,
   and without C<ANY> warranty! Have fun.

=head1 SYNOPSIS

  use Device::Gsm;

  my $gsm = new Device::Gsm( port => '/dev/ttyS1', pin => 'xxxx' );

  if( $gsm->connect() ) {
      print "connected!\n";
  } else {
      print "sorry, no connection with gsm phone on serial port!\n';
  }
 
  # Register to GSM network (you must supply PIN number in above new() call)
  $gsm->register();
 
  # Get the manufacturer and model code of device
  my $mnf   = $gsm->manufacturer();
  my $model = $gsm->model();
  print 'soft version is ", $gsm->software_version(), "\n";

  my $imei = $gsm->imei() or
	$imei = $gsm->serial_number();
 
  # Test for command support
  if( $self->test_command('CGMI') ) {
      # `AT+CGMI' is supported!
  } else {
      # No luck, CGMI command not available
  }
 
  print 'Service number is now: ', $gsm->service_number(), "\n";
  $gsm->service_number( '+001505050' );   # Sets new number
  
  # Send quickly a short text message
  $modem->send_sms(
      recipient => '+3934910203040',
      content   => 'Hello world! from Device::Gsm'
  );

  # The long way...
  $modem->send_sms(

      recipient => '34910203040',
      content   => 'Hello world again, with more args',

      # SMS Class (can be `normal' or `flash')
      # `flash' mode delivers instantly!
      class     => 'normal',

      # SMS sending mode
      # try `text' or old phones or GSM modems
      # `pdu' is the default nowadays
      mode      => 'pdu'
  );
 

=head1 DESCRIPTION

C<Device::Gsm> class implements basic GSM functions, network registration and SMS sending.

This class supports also C<PDU> mode to send C<SMS> messages, and should be
fairly usable. I'm developing and testing it under C<Linux RedHat 7.1>
with a 16550 serial port and C<Siemens C35i> / C<C45> GSM phones attached with
a Siemens-compatible serial cable.

Please be kind to the universe and contact me if you have troubles or you are
interested in this.

=head2 REQUIRES

=over 4

=item * 

Device::Modem, which in turn requires

=item *

Device::SerialPort (or Win32::SerialPort on Windows machines)

=back

=head2 EXPORT

None


=head1 TO-DO

=over 4

=item Validity Period 

Support C<validity period> option on SMS sending. Tells how much time the SMS
Service Center must hold the SMS for delivery.

=item Profiles

Build a profile of the GSM device used, so that we don't have to C<always>
test each command to know whether it is supported or not, because this takes
too time to be done every time.

=back


=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

L<Device::Modem>, L<Device::SerialPort>, L<Win32::SerialPort>, perl(1)

=cut
