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
# $Id: Gsm.pm,v 1.7 2002-04-03 21:38:37 cosimo Exp $

package Device::Gsm;
$Device::Gsm::VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/;

use strict;
use Device::Modem;

# Connection defaults to 19200 baud. This seems to be the optimal
# rate for serial links to new gsm devices
$Device::Gsm::BAUDRATE = 19200;

@Device::Gsm::ISA = ('Device::Modem');

# Connect on serial port to gsm device
# see parameters on Device::Modem::connect()
sub connect {
	my $me = shift;
	my %aOpt;
	%aOpt = @_ if(@_);

	# GSM defaults to 9600 baud
	$aOpt{'baudrate'} ||= $Device::Gsm::BAUDRATE;

	$me->SUPER::connect( %aOpt );
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

# send_sms( recipient, text, success )
#
# for now, this works only in text mode, not PDU mode!
# so it's not very usable nowadays... :-(
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

  # NOT YET DEFINED!
  my $gsm = new Device::Gsm( port => '/dev/ttyS1', pin => '0124' );

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
 
  # Send a short text message (SMS in text mode *only*, no PDU)
  $modem->send_sms( '0123456789', 'A little message from Device::Gsm' );
 

=head1 DESCRIPTION

Device::Gsm class implements basic GSM network registration and SMS sending functions.
For now, it is only an example that inherits from Device::Modem for all low-level functions.
It is planned to add more custom GSM commands support, with device identification, and so on...

Actually, this was a rather dated module, that does not support PDU mode
(for example) and it is now undergoing a major rewrite.

So please be patient and contact me if you are interested in this.

=head2 REQUIRES

=over 4

=item * 

Device::Modem, which in turn requires

=item *

Device::SerialPort

=back

=head2 EXPORT

None


=head1 TO-DO

=over 4

=item *

Too many things, but your suggestions are welcome...

=back


=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

Device::Modem(3), Device::SerialPort(3), perl(1)

=cut
