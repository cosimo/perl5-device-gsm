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
# $Id: Gsm.pm,v 1.22 2003-09-14 17:09:56 cosimo Exp $

package Device::Gsm;
$Device::Gsm::VERSION = sprintf "%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/;

use strict;
use Device::Modem;
use Device::Gsm::Sms;
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

#
# Hangup and terminate active call(s)
# this overrides the `Device::Modem::hangup()' method
#
sub hangup {
	my $self = shift;
	$self->log->write('info', 'hanging up...');
	$self->attention();
	$self->atsend( 'AT+CHUP' . Device::Modem::CR );
	$self->flag('OFFHOOK', 0);
	$self->answer();
}

#
# Who is the manufacturer of this device?
#
sub manufacturer() {
	my $self = shift;
	my($ok, $man);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMI') ) {

		$self->atsend( 'AT+CGMI' . Device::Modem::CR );
		($ok, $man) = $self->parse_answer();

		$self->log->write('info', 'manufacturer of this device appears to be ['.$man.']');

	}

	return $man || $ok;

}

#
# What is the model of this device?
#
sub model() {
	my $self = shift;
	my($code, $model);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMM') ) {

		$self->atsend( 'AT+CGMM' . Device::Modem::CR );
		($code, $model) = $self->parse_answer();

		$self->log->write('info', 'model of this device is ['.$model.']');

	}

	return $model || $code;
}

#
# Get handphone serial number (IMEI number)
#
sub imei() {
	my $self = shift;
	my($code,$imei);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGSN') ) {

		$self->atsend( 'AT+CGSN' . Device::Modem::CR );
		($code, $imei) = $self->parse_answer();

		$self->log->write('info', 'IMEI code is ['.$imei.']');

	}

	return $imei || $code;
}

# Alias for `imei()' is `serial_number()'
*serial_number = *imei;

#
# Get mobile phone signal quality (expressed in dBm)
#
sub signal_quality() {
	my $self = shift;
	# Error code, dBm (signal power), bit error rate
	my($code, $dBm, $ber);

	# Test if signal quality command is implemented
	if( $self->test_command('CSQ') ) {

		$self->atsend( 'AT+CSQ' . Device::Modem::CR );
		($code, $dBm) = $self->parse_answer();

		if( $dBm =~ /\+CSQ: (\d+),(\d+)/ ) {

			($dBm, $ber) = ($1, $2);

			# Further process dBm number to obtain real dB power
			if( $dBm > 30 ) {
				$dBm = -51;
			} else {
				$dBm = -113 + ($dBm << 1);
			}

			$self->log->write('info', 'signal dBm power is ['.$dBm.'], bit error rate ['.$ber.']');

		} else {

			$self->log->write('warn', 'cannot obtain signal dBm power');

		}

	} else {

		$self->log->write('warn', 'signal quality command not supported!');

	}

	return $dBm;

}


#
# Get the GSM software version on this device
#
sub software_version() {
	my $self = shift;
	my($code, $ver);

	# Test if manufacturer code command is supported
	if( $self->test_command('CGMR') ) {

		$self->atsend( 'AT+CGMR' . Device::Modem::CR );
		($code, $ver) = $self->parse_answer();

		$self->log->write('info', 'GSM version is ['.$ver.']');

	}

	return $ver || $code;
}

#
# Test support for a specific command
#
sub test_command {
	my($self, $command) = @_;

	# Standard test procedure for every command
	$self->log->write('info', 'testing support for command ['.$command.']');
	$self->atsend( "AT+$command=?" . Device::Modem::CR );

	# If answer is ok, command is supported
	my $ok = ($self->answer() || '') =~ /OK/o;
	$self->log->write('info', 'command ['.$command.'] is '.($ok ? '' : 'not ').'supported');

	$ok;
}

#
# Read all messages on SIM card (XXX must be registered on network)
#
sub messages() {
	my $self = shift;
	$self->log->write('info', 'reading messages on SIM card');

	# Register on network (give your PIN number for this!)
	#return undef unless $self->register();
	$self->register();

	#
	# Read messages (XXX need to check if device supports CMGL with `stat'=4)
	#
	$self->atsend('AT+CMGL=4'.Device::Modem::CR);
	my($messages) = $self->answer();

	#if( $code =~ /ERROR/ ) {
	#	$self->log->write('error', 'cannot read SMS messages on SIM: ['.$code.']');
	#	return ();
	#}

	# Ok, messages read, now convert from PDU and store in object
	$self->log->write('debug', 'messages='.$messages );

	my @data = split /\r+\n*/m, $messages;

	# Check for errors on SMS reading
	my $code;
	if( ($code = pop @data) =~ /ERROR/ ) {
		$self->log->write('error', 'cannot read SMS messages on SIM: ['.$code.']');
		return ();
	}

	my @message = ();
	my $current;

	#
	# Parse received data (result of +CMGL command)
	#
	while( @data ) {

		$self->log->write('debug', 'data[] = ', $data[0] );

		# Instance new message object
		my $msg = new Device::Gsm::Sms(
			header => shift @data,
			pdu    => shift @data
		);

		# Check if message has been instanced correctly
		if( ref $msg ) {
			push @message, $msg;
		} else {
			$self->log->write('info', 'could not instance message!');
		}

	}

	$self->log->write('info', 'found '.(scalar @message).' messages on SIM. Reading.');

	return @message;
}

#
# Register to GSM service provider network
#
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

#
# _send_sms_text( %options ) : sends message in text mode
#
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
	$me->log->write('info', 'Selected text format for message sending');

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


#
# _send_sms_pdu( %options )  : sends message in PDU mode
#
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
	$me->log->write('info', 'Selected PDU format for msg sending');

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

# Transform ascii char set to gsm 3.38 charset
{

	my @gsm = map chr, 0 .. 255;
	$gsm[0] = '@';
	$gsm[1] = '£';
	$gsm[2] = '$';
	$gsm[3] = '¥';
	$gsm[5] = 'é';
	$gsm[4] = 'è';
	$gsm[6] = 'ù';
	$gsm[7] = 'ì';
	$gsm[8] = 'ò';
	$gsm[9] = 'ç';
	$gsm[11] = 'ø';
	$gsm[12] = $gsm[11];
	$gsm[15] = 'å';
	$gsm[17] = '_';
 	$gsm[20] = '^';
 	$gsm[27] = chr(164); # '¤';
	$gsm[29] = 'æ';
	$gsm[30] = chr(223); # 'ß';
	$gsm[31] = chr(201); # 'É';
	$gsm[36] = '¤';
# 	$gsm[47] = '\\';
#	$gsm[60] = '[';
#	$gsm[62] = ']';
 	$gsm[92] = '/';
 	$gsm[95] = '§';
	$gsm[123] = 'ä';
	$gsm[127] = 'à';
	$gsm[124] = 'ö';
	$gsm[125] = 'ñ';
	$gsm[126] = 'ü';
	$gsm[164] = '¤';
 	$gsm[232] = 'è';
 	$gsm[233] = 'é';
 	$gsm[236] = 'ì';
 	$gsm[248] = 'ø';

=cut

CODE 	$gsm[95] = '§';
CODE 	$gsm[27] = '¤';
CODE 	$gsm[101] = 'é';
CODE 	$gsm[5] = 'è';
CODE 	$gsm[4] = 'g';
CODE 	$gsm[103] = 'h';
CODE 	$gsm[104] = 'i';
CODE 	$gsm[105] = '4';
CODE 	$gsm[52] = 'ì';
CODE 	$gsm[7] = '[';
CODE 	$gsm[27] = '\';
CODE 	$gsm[60] = ']';
CODE 	$gsm[27] = '^';
CODE 	$gsm[47] = 'j';
CODE 	$gsm[27] = 'k';
CODE 	$gsm[62] = 'l';
CODE 	$gsm[27] = '5';
CODE 	$gsm[20] = 'm';
CODE 	$gsm[106] = 'n';
CODE 	$gsm[107] = 'o';
CODE 	$gsm[108] = '6';
CODE 	$gsm[53] = 'ñ';
CODE 	$gsm[109] = 'ò';
CODE 	$gsm[110] = 'ø';
CODE 	$gsm[111] = 'ö';
CODE 	$gsm[54] = 'p';
CODE 	$gsm[125] = 'q';
CODE 	$gsm[8] = 'r';
CODE 	$gsm[12] = 's';
CODE 	$gsm[124] = '7';
CODE 	$gsm[112] = 't';
CODE 	$gsm[113] = 'u';
CODE 	$gsm[114] = 'v';
CODE 	$gsm[115] = '8';
CODE 	$gsm[55] = 'ù';
CODE 	$gsm[116] = 'ü';
CODE 	$gsm[117] = 'w';
CODE 	$gsm[118] = 'x';
CODE 	$gsm[56] = 'y';
CODE 	$gsm[6] = 'z';
CODE 	$gsm[126] = '9';
CODE 	$gsm[119] = '0';
CODE 	$gsm[120] = '+';
CODE 	$gsm[121] = '';
CODE 	$gsm[122] = '';
CODE 	$gsm[57] = '';
CODE 	$gsm[48] = '';
CODE 	$gsm[43] = '';

=cut

=cut

	# The following is the GSM 3.38 standard charset, as shown
	# on some Siemens documentation found on the internet
	my $gsm_charset = join('',
		'@»$»»»»»»»'."\n".'»»'."\r".'»»»',  # 16
		'»»»»»»»»»»»»ß»»',
		' !"# %&‘()*+,-./',
		'0123456789:;<=>?',
		'-ABCDEFGHIJKLMNO',
		'PQRSTUVWXYZÄÖ»Ü»',
		'¨abcdefghijklmno',
		'pqrstuvwxyzäö»ü»'
	);

=cut

	my $gsm_charset = join('',@gsm);

sub _ascii2gsm {
	my $self = shift;
	my $ascii = shift;

	return '' unless $ascii;

	my $gsm = '';
	my $n = 0;
	for( ; $n < length($ascii) ; $n++ ) {
		$gsm .= chr index($gsm_charset, substr($ascii, $n, 1));
	}

	return $gsm;
}

sub _gsm2ascii {
	my $self = shift;
	my $gsm = shift;
	return '' unless $gsm;

	my $ascii = '';
	my $n = 0;

	for( ; $n < length($gsm) ; $n++ ) {

		my $c = ord( substr( $gsm, $n, 1 ) );

		# Extended charset ?
		if( $c == 0x1B ) {                          # "escape extended mode"
			$n++;
			$c = ord(substr($gsm, $n, 1));
			if( $c == 0x65 ) {                  # 'e'
				$ascii .= chr(164);         # iso_8859_15 EURO SIGN
			} elsif( $c == 0x14 ) {
				$ascii .= '^';
			} elsif( $c == 0x3C ) {
				$ascii .= '[';
			} elsif( $c == 0x2F ) {
				$ascii .= '\\';
			} elsif( $c == 0x3E ) {
				$ascii .= ']';
			} else {
				$ascii .= chr($c);          # Un-managed "extended" chars
			}
		} else {
			# Standard GSM 3.38 encoding
			$ascii .= substr( $gsm_charset, $c, 1 );
		}
	}

	return $ascii;
}

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
      print "sorry, no connection with gsm phone on serial port!\n";
  }

  # Register to GSM network (you must supply PIN number in above new() call)
  $gsm->register();

  # Get the manufacturer and model code of device
  my $mnf   = $gsm->manufacturer();
  my $model = $gsm->model();
  print "soft version is ", $gsm->software_version(), "\n";

  my $imei = $gsm->imei() or
	$imei = $gsm->serial_number();

  # Test for command support
  if( $gsm->test_command('CGMI') ) {
      # `AT+CGMI' is supported!
  } else {
      # No luck, CGMI command not available
  }


  print 'Service number is now: ', $gsm->service_center(), "\n";
  $gsm->service_center( '+001505050' );   # Sets new number


  # Send quickly a short text message
  $gsm->send_sms(
      recipient => '+3934910203040',
      content   => 'Hello world! from Device::Gsm'
  );


  # The long way...
  $gsm->send_sms(

      recipient => '34910203040',
      content   => 'Hello world again, with more args',

      # SMS sending mode
      # try `text' on old phones or GSM modems
      # `pdu' is the default nowadays
      mode      => 'pdu',

      # SMS Class (can be `normal' or `flash')
      # `flash' mode delivers instantly!
      class     => 'normal'
  );

  # Test network signal
  print "Signal power seems to be ", $gsm->signal_quality(), " dBm\n";

  # Get list of Device::Gsm::Sms message objects
  # see `examples/read_messages.pl' for all the details
  my @messages = $gsm->messages();


=head1 DESCRIPTION

C<Device::Gsm> class implements basic GSM functions, network registration and SMS sending.

This class supports also C<PDU> mode to send C<SMS> messages, and should be
fairly usable. I'm developing and testing it under C<Linux RedHat 7.1>
with a 16550 serial port and C<Siemens C35i> / C<C45> GSM phones attached with
a Siemens-compatible serial cable.

Please be kind to the universe and contact me if you have troubles or you are
interested in this.

Please be monstruosly kind to the universe and (if you don't mind spending an SMS)
use the `examples/send_to_cosimo.pl' script to make me know that Device::Gsm works
with your device (thanks!).

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

=item Spooler

Build a simple spooler program that sends all SMS stored in a special
queue (that could be a simple filesystem folder).

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
