# Declare object name
package device::gsm;
$device::gsm::VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

# Module dependencies
use strict;
use init;
use log;

# This is an AT-compliant device
use device::at;

# Connection defaults
$device::gsm::BAUDRATE = 9600;

# Hierarchy information
@device::gsm::ISA = qw( device::at );

#/**
# * @method       connect
# *
# * Connect on serial port to gsm device
# * via serial port
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
	$rOpt->{BAUDRATE} ||= $device::gsm::BAUDRATE;

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
	$me->atsend( 'AT+CPIN?' . device::at::CR );
	
	# Get answer
	my $cReply = $me->answer();

	if( $cReply =~ /READY/ ) {
		
		$me->log->write( 'Already registered on network. Ready to send.' );
		$lOk = 1;
		
	} elsif( $cReply =~ /SIM PIN/ ) {
		
		# Pin request, sending PIN code
		$me->log->write( 'PIN requested: sending...' );
		$me->atsend( qq[AT+CPIN="$$me{'PIN'}"] . device::at::CR );
		
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
# * @method       sendSms
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
sub sendSms {
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
		$me->atsend( qq[AT+CMGS="$num"] . device::at::CR );
		$me->atsend( $text . device::at::CTRL_Z );
		
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
