# Sms::Token::OA - SMS OA (originating address) token
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
# $Id: OA.pm,v 1.3 2006-04-20 20:07:19 cosimo Exp $

package Sms::Token::OA;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::OA::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes OA from message
sub decode {
	my($self, $rMessage) = @_;
	my $ok = 0;

	# Detect originating address length
	my $oa_len    = hex( substr $$rMessage, 0, 2 );

	# Get number type (0x91=international, 0x81=local)
	my $oa_type   = substr( $$rMessage, 2, 2 );

	# Get address
	my $oa_octets = (($oa_len + 1) >> 1) << 1;
	my $reversed_addr = substr( $$rMessage, 4, $oa_octets );
	my $addr;

	# Reverse octets of OA
	while( $reversed_addr ) {
		$addr .= reverse substr $reversed_addr, 0, 2;
		$reversed_addr = substr $reversed_addr, 2;
	}

	# Remove final 'filler' if addr ends with 0xF
	chop $addr if substr($addr, -1) eq 'F';

	$self->set('length'  => $oa_len);
	$self->set('type'    => $oa_type);
	$self->set('address' => $addr);

	$self->data( $oa_len, $oa_type, $addr );

	$self->state( Sms::Token::DECODED );

	# Remove OA from message
	$$rMessage = substr( $$rMessage, 4 + $oa_octets );

	return 1;
}

#
# [token]->encode( [$data] )
#
# encodes originating address (OA)
#
sub encode {
	my $self = shift;
	my $oa_len = $self->get('length');

	# XXX TO BE COMPLETED...
	return $oa_len;

}

sub toString {
	my $self = shift;
	my $str;

	$str = '+' if $self->get('type') eq '91';
	$str .= $self->get('address');

	return $str;
}

1;
