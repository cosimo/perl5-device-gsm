# Device::Gsm - a Perl class to interface GSM devices as AT modems
# Copyright (C) 2000-2002 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# WARNING
#
# This is PRE-ALPHA software, still needs extensive testing and
# support for custom GSM commads, so use it at your own risk,
# and without ANY warranty! Have fun.
#
# $Id: Gsm.pm,v 1.6 2002-03-30 15:48:16 cosimo Exp $

package Device::Gsm;
$Device::Gsm::VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;

use strict;
use Device::SerialPort;
use Device::Modem;

# Connection defaults
$Device::Gsm::BAUDRATE = 9600;

# Hierarchy information
@Device::Gsm::ISA = qw( Device::Modem );

#/**
# * @method       connect
# *
# * Connect on serial port to gsm device
# *
# * @param        reference to hash of options, that must contain:
# *     BAUDRATE  speed of communication (default 9600)
# *     DATABITS  byte length (default 8)
# *     STOPBITS  stop bits (default 1)
# *     PARITY    ... (default 'none')
# *
# * @return       success of connection
# */
sub connect {
	my ($me,$rOpt) = @_;

	# GSM defaults to 9600 baud
	$rOpt->{BAUDRATE} ||= $Device::Gsm::BAUDRATE;

	$me->SUPER::connect( $rOpt );
}


# Who is the manufacturer of this device?
sub manufacturer() {
	my $self = shift;
	my $man;

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMI') ) {

		$self->atsend( 'AT+CGMI' . Device::Modem::CR );
		$man = $self->answer();

		$self->log->write('info', 'manufacturer of this device appears to be ['.$man.']');

	}

	return $man;

}

# What is the model of this device?
sub model() {
	my $self = shift;
	my $model;

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMM') ) {

		$self->atsend( 'AT+CGMM' . Device::Modem::CR );
		$model = $self->answer();

		$self->log->write('info', 'model of this device is ['.$model.']');

	}

	return $model;
}

# Get the GSM software version on this device
sub software_version() {
	my $self = shift;
	my $ver;

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMR') ) {

		$self->atsend( 'AT+CGMR' . Device::Modem::CR );
		$ver = $self->answer();

		$self->log->write('info', 'GSM version is ['.$ver.']');

	}

	return $ver;
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

#/**
# * @method       register
# *
# * Register to GSM service provider network
# *
# * @return       [bool] success of registering
# */
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
		$me->atsend( qq[AT+CPIN="$$me{'PIN'}"] . Device::Modem::CR );
		
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
	
	# XXX Sending number of service provider
	# $me->log -> write( 'Sending service provider number' );
	
}

#/**
# * @method       send_sms
# *
# * Send SMS to handphone number [cRecipient]. The text of
# * SMS to send is in [cText]. Returns a boolean value telling
# * if send has been successful, but *NOT* if SMS reached
# * recipient.
# *
# * @param        cRecipient
# * 	Recipient number
# *
# * @param        cText
# * 	Text of SMS to send
# *
# * @return       lSuccess
# * 	success of sending
# */
sub send_sms {
	my($me, $num, $text) = @_;
	my $lOk = 0;
	my $cReply;

	# Check if registered to network
	if( ! $me->{REGISTERED} ) {
		$me->log->write( 'info', 'Not yet registered, doing now...' );
		$me->register();
	}

	# Again check if registered
	if( ! $me->{REGISTERED} ) {
		
		$me->log->write( 'warning', 'ERROR in registering to network' );
		return $lOk;
		
	} else {
		
		# Send sms in text mode
		$me->atsend( qq[AT+CMGS="$num"] . Device::Modem::CR );
		$me->atsend( $text . Device::Modem::CTRL_Z );
		
		# Get reply and check for errors
		$cReply = $me->answer();
		if( $cReply =~ /ERROR/i ) {
			$me->log->write( 'warning', "ERROR in sending SMS" );
		} else {
			$me->log->write( 'info', "Sent SMS to $num!" );
			$lOk = 1;
		}
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
		$self->atsend('AT+CSCA=?' . Device::Modem::CR );

		# Get answer and check for errors
		$nCenter = $self->answer();

		if( $nCenter =~ /ERROR/ ) {
			$self->log->write('warning', 'error status for "service_center" command');
			$lOk = 0;
		} else {
			$nCenter =~ tr/\r\nA-Z//s;
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

  # NOT YET DEFINED!
  my $gsm = new Device::Gsm( port => '/dev/ttyS1', PIN => '0124' );

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
 
  # What GSM software verson ?
  print 'GSM VERSION is ", $gsm->software_version(), "\n";
 
  # Test for command support
  if( $self->test_command('CGMI') ) {
      # `AT+CGMI' command supported!
  } else {
      # No luck, CGMI command not available
  }
 
  # Set service center number (depends on your network operator)
  $gsm->service_number( '+001505050' );   # This one is fake, not usable!
 
  # Retrieve actual stored service number
  print 'Service number is now: ', $gsm->service_number(), "\n";
 
  # Send a short text message (SMS)
  $modem->send_sms( '0123456789', 'A little message from Device::Gsm' );
 

=head1 DESCRIPTION

Device::Gsm class implements basic GSM network registration and SMS sending functions.
For now, it is only an example that inherits from Device::Modem for all low-level functions.
It is planned to add more custom GSM commands support, with device identification, and so on...

Please feel free to contact me to provide feedback on this.

=head2 REQUIRES

=over 4

=item Device::Modem

=back

=head2 EXPORT

None

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

Device::Modem(3), Device::SerialPort(3), perl(1)

=cut
