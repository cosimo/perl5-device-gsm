# $Id: Pdu.pm,v 1.2 2002-04-08 22:21:44 cosimo Exp $
package Device::Gsm::Pdu;



# encodeAddress( num )
sub encodeAddress {
	my $num = shift();
	$num =~ s/\s+//g;

	my $type = index($num,'+') == 0 ? 91 : 81;
	my $len  = unpack 'H2' => chr( length $num );

	$num .= 'F';
	my @digit = split //, $num;
	my $encoded;

	while( @digit > 1 ) {
		$encoded .= join '', reverse splice @digit, 0, 2;
	}

	$encoded;
}




{
	my( %b2h, %h2b );
	foreach ( 0 .. 255 ) {
		my $v = unpack 'b8', chr;
		$b2h{$v} = uc unpack 'H2' => pack 'b8' => $v;
	}

	foreach ( 0 .. 127 ) {
		$h2b{chr($_)} = unpack 'b7', chr;
	}

sub encodeText ($) {

	my($result, $bits);
	my @char = split // => $_[0];

	map { $bits .= $h2b{$_} } @char; 

#	if( $len = length($bits) % 8 ) {
#		$bits .= '0' x ( 8 - $len );
#	}

	while( length $bits ) {
		$result .= $b2h{ substr $bits, 0, 8 };
		$bits = substr $bits, 8;
	}

	$result;
}

}



1;

