# $Id: 30gsmascii.t,v 1.1 2003-03-25 22:50:26 cosimo Exp $
# test gsm <=> ascii charset conversions

use Test;
use lib '../blib/lib';
use Device::Gsm;

BEGIN { plan tests => 28 };


my @test_string = (
	'$ABC$ABC@ABC@',
	'$$$$@@@@@@@$$',
	join('','A'..'Z'),
	join('','a'..'z'),
	join('','0'..'9'),
	"\r\n\r\r\r\n\n\n",
	'/n/n/n/r/r/r/n/n/n/r/r/r',
	'!@#$%&*()+=<>/- ',
	' !"# %&‘()*+,-./',
	'0123456789:;<=>?',
	'-ABCDEFGHIJKLMNO',
	'PQRSTUVWXYZÄÖÜ',
	'¨abcdefghijklmno',
	'pqrstuvwxyzäöü'
);

#print '\r = ', ord("\r"), "\n";
#print '\n = ', ord("\n"), "\n";

foreach( @test_string ) {

	my $a1 = $_;
	my $a1_copy = $a1;

	my $a2 = Device::Gsm::_gsm2ascii(undef, Device::Gsm::_ascii2gsm(undef, $a1) );

#	print "\$a1[$a1] \$a2[$a2]\n";

	ok( $a1 eq $a2 );

	$a1 = Device::Gsm::_ascii2gsm(undef, $a1_copy);
	$a2 = Device::Gsm::_ascii2gsm(undef, Device::Gsm::_gsm2ascii(undef, $a1) );

	ok( $a1 eq $a2 );

}

# end of test