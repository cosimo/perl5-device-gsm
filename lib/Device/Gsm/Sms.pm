# Device::Gsm::Sms - SMS short text message class (PDU format)
# Copyright (C) 2002 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# $Id: Sms.pm,v 1.1 2003-03-23 12:59:07 cosimo Exp $

package Device::Gsm::Sms;
use strict;
use integer;
use Device::Gsm::Pdu;
use Device::Gsm::Sms::Structure;
use Device::Gsm::Sms::Token;

use constant DCS_7BIT => 0x00;
use constant DCS_8BIT => 0xF6;

sub _log {
	print @_, "\n";
}

#
# new(
#     header => '+CMGL: .....',
#     pdu => '[encoded pdu string]'
# )
#
# creates message object
# 
sub new {
	my($proto, %opt) = @_;
	my $class = ref $proto || $proto;

	# Create new message object
	my $self = {};
	$self->{'options'} = \%opt;

	# Hash to contain token objects after decoding (must be accessible by name)
	$self->{'tokens'}  = {};

	return undef unless( exists $opt{'header'} && exists $opt{'pdu'} );

	_log("NEW SMS OBJECT");
	_log("Header [$opt{header}]");
	_log("PDU    [$opt{pdu}]");

	# Check for valid msg header
	if( $opt{'header'} =~ /\+CMGL:\s*(\d+),(\d+),(\w*),(\d+)/o ) {

		$self->{'index'}  = $1;                        # Position of message in SIM card 
		$self->{'status'} = $2;                        # Status of message (REC READ/UNREAD, STO, ...);
		$self->{'alpha'}  = $3;                        # Alphanumeric representation of sender
		$self->{'length'} = $4;                        # Final length of message
		$self->{'pdu'}    = $opt{'pdu'};               # PDU content

		bless $self, $class;

		if( $self->decode(SMS_DELIVER) ) {
			_log('OK, message decoded correctly!');
		} else {
			_log('CASINO!');
			undef $self;
		}

	} else {

		# Warning: could not parse message header
		undef $self;

	}

	return $self;
}

#
# type(): returns message type in ascii readable format
#
{
	# List of allowed status strings
	my @status = ( 'UNKNOWN', 'REC UNREAD', 'REC READ', 'SENT UNREAD', 'SENT READ' );

	sub status () {
		my $self = shift;
		return $status[ defined $self->{'status'} ? $self->{'status'} : 0 ];
	}

}

sub sender () {
	my $self = shift;
	$self->{'DA'};
}

#
# decode( CMGL_header, pdu_string )
#
# creates a new Device::Gsm::Sms object from
# PDU encoded message string returned by +CMGL commands
#
# If some error occurs, returns undef.
#
#
sub decode2 {
	my($header, $pdu) = @_;
	my %msg = ();
	my $errors = 0;

	# Copy original header/pdu strings
	$msg{'_HEADER'} = $header;
	$msg{'_PDU'} = $pdu;

	#
	# Decode header string
	#
	if( $header =~ /\+CMGL:\s*(\d+),(\d+),(\d*),(\d+)/ ) {
		$msg{'index'}  = $1;
		$msg{'type'}   = $2;
		$msg{'xxx'}    = $3;   # XXX
		$msg{'length'} = $4;
	}

	#
	# Decode all parts of PDU message
	#

	# ----------------------------------- SCA (service center address)
	my $sca_length = hex( substr $pdu, 0, 2 );
	if( $sca_length == 0 ) {
		# No SCA provided, take default
		$msg{'SCA'} = undef;
	} else {
		# Parse SCA address
		print STDERR "SCA length = ", $sca_length, "; ";
		print STDERR "Parsing address ", substr( $pdu, 0, ($sca_length+1) << 1 );
		$msg{'SCA'} = Device::Gsm::Pdu::decode_address( substr($pdu, 0, ($sca_length+1) << 1 ) );
		print STDERR ' = `', $msg{'SCA'}, "'\n";
	}
	
	# ----------------------------------- PDU type
	$pdu = substr $pdu => (($sca_length+1) << 1);
	$msg{'PDU_TYPE'} = substr $pdu, 0, 2; 
	undef $sca_length;

	# ----------------------------------- OA (originating address)
	$pdu = substr $pdu => 2;
	my $oa_length = hex( substr $pdu, 0, 2 );

	$msg{'OA'} = Device::Gsm::Pdu::decode_address( substr($pdu, 0, ($oa_length+1) << 1 ) );
	undef $oa_length;

	# PID      (protocol identifier)
	# DCS      (data coding scheme)
	# SCTS     (service center time stamp)
	# UDL + UD (user data)
	@msg{ qw/PID DCS SCTS UDL UD/ } = unpack 'A2 A2 A14 A2 A*', $pdu;

	#map { $msg{$_} = hex $msg{$_} } qw/PID DCS UDL/;
	#
	# Decode USER DATA in 7/8 bit encoding
	#
	if( $msg{'DCS'} eq '00' ) { # DCS_7BIT
		Device::Gsm::Pdu::decode_text7( $msg{'UD'} );
	} elsif( $msg{'DCS'} eq 'F6' ) { # DCS_8BIT
		Device::Gsm::Pdu::decode_text8( $msg{'UD'} );
	}

	# XXX DEBUG
	foreach( sort keys %msg ) {
		print STDERR 'MSG[', $_, '] = `'.$msg{$_}.'\'', "\n";
	}

	bless \%msg, 'Device::Gsm::Sms';
}


#
# Returns type of sms (SMS_DELIVER || SMS_SUBMIT)
#
sub type {
	my $self = shift;
	if( @_ ) {
		$self->{'type'} = shift;
	}
	$self->{'type'};
}


sub decode {
	my( $self, $type ) = @_;
	$self->{'type'} = $type;

	# Get list of tokens for this message (from ::Sms::Structure)
	my $cPdu        = $self->{'pdu'};
	my @token_names = $self->structure();
	my $decoded     = 1;

	while( @token_names ) {

		# Create new token object
		my $token = new Sms::Token( shift @token_names );
		if( ! defined $token ) {
			$decoded = 0;
			last;
		}

		# If decoding is completed successfully, add token object to message
		_log('PDU BEFORE ['.$cPdu.']', length($cPdu) );

		if( $token->decode(\$cPdu) ) {
			$self->{'tokens'}->{ $token->name() } = $token;
			_log('       ', $token->name(), ' DATA = ', $token->toString() );
		}
		
		_log('PDU AFTER  ['.$cPdu.']', length($cPdu) );

	}

	return $decoded;

}

=pod

=head1 NAME

Device::Gsm::Sms - SMS messages internal class 

=head1 WARNING

   This is C<ALPHA> software, still needs a lot of testing, so
   so use it at your own risk and without C<ANY> warranty! Have fun.

=head1 SYNOPSIS

  #
  # This is an internal class, so you should not have
  # need to use it directly, but ..
  #

  use Device::Gsm::Sms;

  my $msg = new Device::Gsm::Sms(
      header => '+CMGL: ...',
      pdu => `[encoded pdu data]'
  );

  print $msg->recipient() , "\n";
  print $msg->sender()    , "\n";
  print $msg->content()   , "\n";
  print $msg->time()      , "\n";
  print $msg->type()      , "\n";


=head1 DESCRIPTION

C<Device::Gsm::Sms> class implements very basic SMS message object,
that can be used to decode C<+CMGL> GSM command response to build a more
friendly high-level object.

Please be kind to the universe and contact me if you have troubles or you are
interested in this.

=head1 REQUIRES

=over 4

=item * 

Device::Gsm

=back

=head1 EXPORTS

None

=head1 COPYRIGHT

Device::Gsm::Sms - SMS short text message class (in PDU format)
Copyright (C) 2002 Cosimo Streppone, cosimo@cpan.org

This program is free software; you can redistribute it and/or modify
it only under the terms of Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Perl licensing terms for details.

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

L<Device::Gsm>, perl(1)

=cut

