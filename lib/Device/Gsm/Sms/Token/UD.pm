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

use constant UDH1 => '050003'; 
use constant UDH2 => '060804';
use constant UDH1_LENGTH => 7;
use constant UDH2_LENGTH => 8;

use Device::Gsm::Charset;
use Device::Gsm::Pdu;
use Device::Gsm::Sms::Token;
#user data headers in CSMS more here : http://mobiletidings.com/2009/02/18/combining-sms-messages/
my $udh1=UDH1;
my $udh2=UDH2;
#lenght in septets
my $udh1_length=UDH1_LENGTH;
my $udh2_length=UDH2_LENGTH;

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
		if($$rMessage =~ m/($udh1)([A-F0-9]{6})|($udh2)([A-F0-9]{8})/){
		#if matched udh1 : $1 == $udh1; $2 = 1 octet referennumber . 1 octet message count . 1 octet message number 
		#else $3 == $udh1 ; $4= 2 octets referennumber . 1 octet message count . 1 octet message number
		#in ucs2 UDL is count in octect so we decrease udh*_len by 1
		#in ucs2 we forgot about align to septet boundary
		($1 eq $udh1) and $text =Device::Gsm::Pdu::decode_text_UCS2(sprintf("%02X",$ud_len-$udh1_length-1).$') or $text= Device::Gsm::Pdu::decode_text_UCS2(sprintf("%02X",$ud_len-$udh2_length-1).$');
		}else { 
		$text = Device::Gsm::Pdu::decode_text_UCS2($$rMessage);
		}
	} else {
		if($$rMessage =~ m/($udh1)([A-F0-9]{6})|($udh2)([A-F0-9]{8})/){	
		#if udh1 is present we must use decode_text7_udh1 to remove bit of padding, 
		#TODO: investigate why when part of sms is 160 length add 1 to udl for good decoding probably bug in decode_text7_udh1
		($1 eq $udh1) and $text = Device::Gsm::Pdu::decode_text7_udh1(sprintf("%02X",$ud_len-$udh1_length+int($ud_len/160)).$') or $text = Device::Gsm::Pdu::decode_text7(sprintf("%02X",$ud_len-$udh2_length).$');
		}else{
		$text=Device::Gsm::Pdu::decode_text7($$rMessage);	
		}
	$text = Device::Gsm::Charset::gsm0338_to_iso8859($text);
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

