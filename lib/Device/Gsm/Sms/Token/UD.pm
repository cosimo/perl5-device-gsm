# Sms::Token::UD - SMS UD (user data length + user data) token
# Copyright (C) 2002-2006 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# $Id$

package Sms::Token::UD;
use integer;
use strict;
use Device::Gsm::Charset;
use Device::Gsm::Pdu;
use Device::Gsm::Sms::Token;

@Sms::Token::UD::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes user data from message
sub decode {
	my($self, $rMessage) = @_;
	my $ok = 0;

	# Get length of message
	my $ud_len = hex substr($$rMessage, 0, 2);

	# Get alphabet used for encoding from the DCS
	my $dcs = $self->get('_messageTokens')->{'DCS'}->get('_data')->[0];
	my $MASK_ALPHABET = 0x0C;
	my @ALPHABET = ('DEFAULT', '8BITDATA', 'UCS2');
	my $alphabet_key = ($dcs & $MASK_ALPHABET ) >> 2;
	my $alphabet = $ALPHABET[$alphabet_key];

	# Get UDH if it exists
	my $udh;
	my $udh_len;
	my $udhi = $self->get('_messageTokens')->{'PDUTYPE'}->{'_UDHI'};
	if ($udhi) {
		$udh_len = hex substr($$rMessage, 2, 2);
		$udh = substr($$rMessage, 2, ($udh_len+1)*2);
	}

	# Finally get text of message
	my $bin;   # hex encoded UD binary or UCS2 text
	my $text;  # UD converted to text

	if ($alphabet eq 'UCS2' ) {
		if ($udhi) {
			# Get rest of UD
			$bin = substr($$rMessage, 2 + ($udh_len+1)*2);
			$text = Device::Gsm::Pdu::decode_text_UCS2($bin);
		} else {
			$bin = substr($$rMessage, 2);
			$text = Device::Gsm::Pdu::decode_text_UCS2($$rMessage);
		}
	} elsif ($alphabet eq '8BITDATA') {
		if ($udhi) {
			$bin = substr($$rMessage, 2 + ($udh_len+1)*2);
		} else {  
			$bin = substr($$rMessage, 2);
		}
	} else {
		# XXX Here assume that DCS == 0x00 (7 bit coding)
		$text   = Device::Gsm::Pdu::decode_text7($$rMessage);
		if ($udhi) {
			my $udh_len_octet  = (hex substr($$rMessage, 2, 2)) + 1;
			my $udh_len_septet = int($udh_len_octet * 8 / 7) + (($udh_len_octet * 8)%7?1:0);
			# strip off UDH
			$text =~ s/^(.{1,$udh_len_septet})//;
		}
  		# Convert text from GSM 03.38 to Latin 1
		$text = Device::Gsm::Charset::gsm0338_to_iso8859($text);
	}

	$self->set( 'length' => $ud_len );
	$self->set( 'text'   => $text   );
	$self->set( 'udh'    => $udh    );
	$self->set( 'bin'    => $bin    );

	$self->data( $text );
	$self->state( Sms::Token::DECODED );

	# Empty message
	$$rMessage = '';

	return 1;
}

#
# [token]->encode( [$data] )
#
# takes internal token data and encodes it, returning the result or undef value in case of errors
#
sub encode {
	my $self = shift;

	#my $ud_len = $self->get('length');
	my $text   = $self->get('text');

	return Device::Gsm::Pdu::encode_text7($text);

}

1;

