# Device::Gsm::Sms - SMS message simple class that represents a text SMS message
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
# $Id: Sms.pm,v 1.8 2004-03-23 22:27:14 cosimo Exp $

package Device::Gsm::Sms;
use strict;
use integer;
use constant SMS_DELIVER => 0x00;
use constant SMS_SUBMIT  => 0x01;

use Device::Gsm::Pdu;
use Device::Gsm::Sms::Structure;
use Device::Gsm::Sms::Token;

sub _log    { print @_, "\n"; }
sub _parent { $_[0]->{_parent} }

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

    # Store gsm parent object reference
    if( exists $opt{'parent'} ) {
        $self->{'_parent'} = $opt{'parent'};
    }

    # Store options into main object
	$self->{'options'} = \%opt;

	# Hash to contain token objects after decoding (must be accessible by name)
	$self->{'tokens'}  = {};

	return undef unless( exists $opt{'header'} && exists $opt{'pdu'} );

#_log("NEW SMS OBJECT");
#_log("Header [$opt{header}]");
#_log("PDU    [$opt{pdu}]");

	# Check for valid msg header
	if( $opt{'header'} =~ /\+CMGL:\s*(\d+),(\d+),(\w*),(\d+)/o ) {

		$self->{'index'}  = $1;                        # Position of message in SIM card
		$self->{'status'} = $2;                        # Status of message (REC READ/UNREAD, STO, ...);
		$self->{'alpha'}  = $3;                        # Alphanumeric representation of sender
		$self->{'length'} = $4;                        # Final length of message
		$self->{'pdu'}    = $opt{'pdu'};               # PDU content

		bless $self, $class;

		if( $self->decode( Device::Gsm::Sms::SMS_DELIVER ) ) {
#			_log('OK, message decoded correctly!');
		} else {
#			_log('CASINO!');
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

#
# decode( CMGL_header, pdu_string )
#
# creates a new Device::Gsm::Sms object from
# PDU encoded message string returned by +CMGL commands
#
# If some error occurs, returns undef.
#
#
sub _old_decode {
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
		#print STDERR "SCA length = ", $sca_length, "; ";
		#print STDERR "Parsing address ", substr( $pdu, 0, ($sca_length+1) << 1 );
		$msg{'SCA'} = Device::Gsm::Pdu::decode_address( substr($pdu, 0, ($sca_length+1) << 1 ) );
		#print STDERR ' = `', $msg{'SCA'}, "'\n";
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
	#foreach( sort keys %msg ) {
	#	print STDERR 'MSG[', $_, '] = `'.$msg{$_}.'\'', "\n";
	#}

	bless \%msg, 'Device::Gsm::Sms';
}


sub decode {
	my( $self, $type ) = @_;
	$self->{'type'} = $type;

	# Get list of tokens for this message (from ::Sms::Structure)
	my $cPdu        = $self->{'pdu'};

	# Check that PDU is not empty
	return 0 unless $cPdu;

	# Backup copy for "backtracking"
	my $cPduCopy    = $cPdu;

	my @token_names = $self->structure();
	my $decoded     = 1;

	while( @token_names ) {

		# Create new token object
		my $token = new Sms::Token( shift @token_names, {messageTokens => $self->{'tokens'}} );
		if( ! defined $token ) {
			$decoded = 0;
			last;
		}

		# If decoding is completed successfully, add token object to message
#_log('PDU BEFORE ['.$cPdu.']', length($cPdu) );

		if( $token->decode(\$cPdu) ) {

			# Store token object into SMS message
			$self->{'tokens'}->{ $token->name() } = $token;

			# Catch message type indicator (MTI) and re-load structure
			if( $token->name() eq 'PDUTYPE' && $token->MTI() != $type ) {

#_log('token PDUTYPE, data='.$token->data().' MTI='.$token->get('MTI').' ->MTI()='.$token->MTI());

				#
				# This is a SMS-SUBMIT message, so:
				#
				# 1) change type
				# 2) restore original PDU message
				# 3) reload token structure
				# 4) restart decoding
				#
				$self->type( $type = SMS_SUBMIT );    # (!) ++
				$cPdu = $cPduCopy;
				@token_names = $self->structure();

#_log('RESTARTING DECODING AFTER MTI DETECTION');
#<STDIN>;
				redo;
			}

#_log('       ', $token->name(), ' DATA = ', $token->toString() );

		}

#_log('PDU AFTER  ['.$cPdu.']', length($cPdu) );

	}

#_log("\n", 'PRESS ENTER TO CONTINUE'); <STDIN>;

	return $decoded;

}

#
# Delete an sms message
#
sub delete {
    my $self = $_[0];
    my $gsm  = $self->_parent();
    my $ok;

    # Try to delete message
    my $msg_index = $self->index();

    # Issue delete command
    if( ref $gsm && $msg_index > 0 ) {
        $ok = $gsm->deleteMessage($msg_index);
    } else {
        $gsm->log->write('could not delete sms n.'.$msg_index.'. Base class not found!');
        $ok = undef;
    }

    return $ok;
}

#
# Returns message own index number (position) 
#
sub index {
	my $self = $_[0];
    return $self->{'index'};
}

#
# Only valid for SMS_SUBMIT messages (?)
#
sub recipient {
	my $self = shift;
	if( $self->type() == SMS_SUBMIT ) {
		my $t = $self->token('DA');
		return $t->toString() if $t;
	}
}

#
# Only valid for SMS_DELIVER messages (?)
#
sub sender {
	my $self = shift;
	if( $self->type() == SMS_DELIVER ) {
		my $t = $self->token('OA');
		return $t->toString() if $t;
	}
}

sub text {
	my $self = shift;
	my $t = $self->token('UD');
	return $t->toString() if $t;
}

sub token ($) {
	my($self, $token_name) = @_;
	return undef unless $token_name;

	if( exists $self->{'tokens'}->{$token_name} ) {
		return $self->{'tokens'}->{$token_name};
	} else {
		warn('undefined token '.$token_name.' for this sms');
		return undef;
	}
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



=pod

=head1 NAME

Device::Gsm::Sms - SMS message internal class that represents a single text SMS message

=head1 SYNOPSIS

    # A list of Device::Gsm::Sms messages is returned by
    # Device::Gsm messages() method.

    use Device::Gsm;
    ...
    @sms = $gsm->messages();

    if( @sms ) {
        foreach( @sms ) {
            print $msg->recipient() , "\n";
            print $msg->sender()    , "\n";
            print $msg->content()   , "\n";
            print $msg->time()      , "\n";
            print $msg->type()      , "\n";
        }
    }

    # Or you can instance a sms message from raw PDU data
    my $msg = new Device::Gsm::Sms(
        header => '+CMGL: ...',
        pdu    => `[encoded pdu data]'
    );

    if( defined $msg ) {
        print $msg->recipient() , "\n";
        print $msg->sender()    , "\n";
        print $msg->content()   , "\n";
        print $msg->time()      , "\n";
        print $msg->type()      , "\n";
    }

=head1 DESCRIPTION

C<Device::Gsm::Sms> class implements very basic SMS message object,
that can be used to decode C<+CMGL> GSM command response to build a more
friendly high-level object.

=head1 METHODS

The following is a list of methods applicable to C<Device::Gsm::Sms> objects.


=head2 decode()

Starts the decoding process of pdu binary data. If decoding process 
ends in success, return value is true and sms object is filled with
all proper values.

If decoding process has errors or pdu data is not provided, return
value is 0 (zero).


=head2 delete()

Delete the current SMS message from sim card.
Example:

    $gsm = Device::Gsm->new();
    ...
    my @msg = $gsm->messages();
    $msg[0] && $msg[0]->delete();

=head2 new()

Basic constructor. You can build a new C<Device::Gsm::Sms> object from the
raw B<+CMGL> header and B<PDU> data. Those data is then decoded and a new
sms object is instanced and all information filled, to be available
for subsequent method calls.

The allowed parameters to new() method are:

=over 4

=item header

This is the raw B<+CMGL> header string as modem outputs when you
issue a B<+CMGL> command

=item pdu

Binary encoded sms data

=back


=head2 index()

Returns the sms message index number, that is the position of message in the
internal device memory or sim card.
This number is used for example to delete the message.

    my $gsm = Device::Gsm->new(port=>'/dev/ttyS0');
    ...
    my @messages = $gsm->messages();
    ...
    # Delete the first returned message
    my $msg = shift @messages;
    $gsm->delete_sms( $msg->index() );

=head2 recipient()

Returns the sms recipient number (destination address = DA)
as string (ex.: C<+39012345678>).

=head2 sender()

Returns the sms sender number (originating address = OA) as string.

=head2 status()

Status of the message can be one value from the following list:

=for html
<FORM><SELECT><OPTION>UNKNOWN<OPTION>REC UNREAD<OPTION>REC READ<OPTION>SENT UNREAD<OPTION>SENT READ</SELECT></FORM>

=for pod
'UNKNOWN', 'REC UNREAD', 'REC READ', 'SENT UNREAD', 'SENT READ'

=head2 text()

Returns the textual content of sms message

=head2 token()

Returns the given PDU token of the decoded message (internal usage).

=head2 type()

SMS messages can be of two types: SMS_SUBMIT and SMS_DELIVER, that are defined by
two constants with those names. type() method returns one of these two values.

Example:

	if( $sms->type() == Device::Gsm::Sms::SMS_DELIVER ) {
		# ...
	}
	elsif( $sms->type() == Device::Gsm::Sms::SMS_SUBMIT ) {
		# ...
	}

=head1 REQUIRES

=over 4

=item *

Device::Gsm

=back

=head1 EXPORTS

None

=head1 TODO

=over 4

=item *

Complete and proof-read documentation and examples

=back

=head1 COPYRIGHT

Device::Gsm::Sms - SMS message simple class that represents a text SMS message

Copyright (C) 2002-2004 Cosimo Streppone, cosimo@cpan.org

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
