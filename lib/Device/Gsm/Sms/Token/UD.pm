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

	# Finally get text of message
	my $dcs= $self->get('_messageTokens')->{'DCS'}->get('_data')->[0];
	my $text;
	if ($dcs == 8) {
		$text = Device::Gsm::Pdu::decode_text_UCS2($$rMessage);
	} else {
		# XXX Here assume that DCS == 0x00 (7 bit coding)
		$text   = Device::Gsm::Pdu::decode_text7($$rMessage);

  		# Convert text from GSM 03.38 to Latin 1
		$text      = Device::Gsm::Charset::gsm0338_to_iso8859($text);
	} 

	$self->set( 'length' => $ud_len );
	$self->set( 'text'   => $text   );

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

