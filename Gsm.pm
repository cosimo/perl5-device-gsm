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
# $Id: Gsm.pm,v 1.2 2002-03-25 06:24:06 cosimo Exp $

package Device::Gsm;
$Device::Gsm::VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

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
		$me->log-> write( 'Not yet connected. Doing it now...' );
		if( ! $me->connect() ) {
			$me->log->write( 'ERROR: No connection!' );
			return $lOk
		}
	}

	# Send PIN status query
	$me->log->write( 'PIN status query' );
	$me->atsend( 'AT+CPIN?' . Device::Modem::CR );
	
	# Get answer
	my $cReply = $me->answer();

	if( $cReply =~ /READY/ ) {
		
		$me->log->write( 'Already registered on network. Ready to send.' );
		$lOk = 1;
		
	} elsif( $cReply =~ /SIM PIN/ ) {
		
		# Pin request, sending PIN code
		$me->log->write( 'PIN requested: sending...' );
		$me->atsend( qq[AT+CPIN="$$me{'PIN'}"] . Device::Modem::CR );
		
		# Get reply
		$cReply = $me->answer();

		# Test reply		
		if( $cReply !~ /ERROR/ ) {
			$me->log->write( 'PIN accepted. Ready to send.' );
			$lOk = 1;
		} else {
			$me->log->write( 'PIN rejected' );
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
		$me->log->write( 'Not yet registered, doing now...' );
		$me->register();
	}

	# Again check if registered
	if( ! $me->{REGISTERED} ) {
		
		$me->log->write( 'ERROR in registering to network' );
		return $lOk;
		
	} else {
		
		# Send sms
		$me->atsend( qq[AT+CMGS="$num"] . Device::Modem::CR );
		$me->atsend( $text . Device::Modem::CTRL_Z );
		
		# Get reply and check for errors
		$cReply = $me->answer();
		if( $cReply =~ /ERROR/i ) {
			$me->log->write( "ERROR in sending SMS" );
		} else {
			$me->log->write( "Sent SMS to $num!" );
			$lOk = 1;
		}
	}
	
	$lOk
}

1;
