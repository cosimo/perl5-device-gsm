# Device::Gsm::Pdu - PDU encoding/decoding functions for Device::Gsm class 
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
# $Id: Pdu.pm,v 1.4 2002-04-14 08:50:37 cosimo Exp $

package Device::Gsm::Pdu;

# decode a pdu encoded phone number into human readable format 
sub decode_address {
	my $address = shift or return;

	my $number;
	my($length, $type, $bcd_digits) = unpack('A2 A2 A*', $address);

	# Reverse each pair of bcd digits
	while( $bcd_digits ) {
		$number .= reverse substr( $bcd_digits, 0, 2 );
		$bcd_digits = substr $bcd_digits, 2;
	}

	# Truncate last `F' if found
	$number = substr( $number, 0, hex($length) );

	# If number is international, put a '+' sign before
	$number = '+'.$number if $type == 91;

	return $number;
}

sub encode_address {
	my $num = shift();
	$num =~ s/\s+//g;

	my $type = index($num,'+') == 0 ? 91 : 81;

	# Remove all non-numbers
	$num =~ s/\D//g;

	my $len  = unpack 'H2' => chr( length $num );

	$num .= 'F';
	my @digit = split // => $num;
	my $encoded;

	while( @digit > 1 ) {
		$encoded .= join '', reverse splice @digit, 0, 2;
	}

	uc $len . $type . $encoded;
}


{
	my( %b2h, %h2b );
	foreach ( map { chr } 0 .. 255 ) {
		my $v = unpack 'b8' => $_;
		$b2h{$v} = uc unpack 'H2' => $_;
	}

	foreach ( map { chr } 0 .. 127 ) {
		$h2b{$_} = unpack 'b7' => $_;
	}

sub encode_text7($) {

	my($result, $bits);
	my @char = split // => $_[0];

	# Expand in 8 bit octets
	map { $bits .= $h2b{$_} } @char; 

	if( $len = length($bits) % 8 ) {
		$bits .= '0' x ( 8 - $len );
	}

	while( length $bits ) {
		$result .= $b2h{ substr $bits, 0, 8 };
		$bits = substr $bits, 8;
	}

	uc ( unpack 'H2' => chr(scalar @char) ) .   # length in septets
		$result                                 # encoded text
}

}

1;

=head1 NAME

Device::Gsm::Pdu - library to manage PDU encoded data for GSM messaging

=head1 WARNING 

   This is C<PRE-ALPHA> software, still needs extensive testing and
   support for custom GSM commands, so use it at your own risk,
   and without C<ANY> warranty! Have fun.

=head1 NOTICE

	This module is meant to be used internally by C<Device::Gsm> class,
	so you probably do not want to use it directly.

=head1 SYNOPSIS

  use Device::Gsm::Pdu;

  # DA is destination address
  $DA = Device::Gsm::Pdu::encode_address('+39347101010');
  $number = Device::Gsm::Pdu::decode_address( $DA );

  # Encode 7 bit text to send messages
  $text = Device::Gsm::Pdu::encode_text7('hello');

=head1 DESCRIPTION

C<Device::Gsm::Pdu> module includes a few basic functions to deal with SMS in PDU mode,
such as encoding GSM addresses (phone numbers) and, for now only, 7 bit text.

=head1 FUNCTIONS

=head2 decode_address( pdu_encoded_address )

Takes a PDU encoded address and decodes into human-readable mobile number.
If number type is international, result will be prepended with a `+' sign.

Clearly, it is intended as an internal function.

=head2 Example

	print Device::Gsm::Pdu::decode_address( '0B919343171010F0' );
	# prints `+39347101010';

=head2 encode_address( mobile_number )

Takes a mobile number and encodes it as DA (destination address).
If it begins with a `+', as in `+39328101010', it is treated as an international
number.

=head2 Example

	print Device::Gsm::Pdu::encode_address( '+39347101010' );
	# prints `0B919343171010F0'

=head2 encode_text7( text_string )

Encodes some text ASCII string in 7 bits PDU format, including a header byte
which tells the length is septets. This is the only 100% supported mode to
encode text.

=head2 Example

	print Device::Gsm::Pdu::encode_text7( 'hellohello' );
	# prints `0AE832...'

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it only under the terms of Perl itself.

=head1 SEE ALSO

Device::Gsm(3), perl(1)

