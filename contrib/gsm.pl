use strict;
my @A2G;
my @G2A;

@A2G = @G2A = map { chr } 0 .. 255;

$A2G[  0] = '@';
$A2G[  2] = '$';
$A2G[  4] = 'e';
$A2G[  5] = 'e';
$A2G[  7] = 'i';
$A2G[ 15] = 'a';
$A2G[ 31] = 'E';
$A2G[ 92] = 'O';
$A2G[ 94] = 'U';
$A2G[124] = 'o';
$A2G[126] = 'u';
$A2G[127] = 'a';

$G2A[ ord('@') ] = 0;
$G2A[ ord('$') ] = 2;

sub ascii2gsm {
	my $str = shift;
	return join( '', map { $A2G[ ord($_) ] } split('',$str) );
}

sub gsm2ascii {
	my $str = shift;
	return join( '', map { $G2A[ ord($_) ] } split('',$str) );
}

sub translate {
	my ($self, $msg) = @_;
	$msg=~ tr (\x00\x02) (\@\$);
	$msg=~ tr (\x07\x0f\x7f\x04\x05\x1f\x5c\x7c\x5e\x7e) (iaaeeEOoUu);	
	return $msg;
}

sub inversetranslate {
	my ($self, $msg) = @_;
	$msg=~ tr (\@\$) (\x00\x02);
	$msg=~ tr (iaaeeEOoUu) (\x07\x0f\x7f\x04\x05\x1f\x5c\x7c\x5e\x7e);	
	return $msg;
}

my $str = join('', map { chr } 0..255 );

print "OK!\n" if( ascii2gsm($str) eq translate(undef,$str) );
print "OK!\n" if( gsm2ascii($str) eq inversetranslate(undef,$str) );

#print "ascii2gsm=".ascii2gsm($str)."\n";
#print "translate=".translate(undef,$str)."\n";

=cut

use Benchmark;
timethese(500_000, {
	translate => 'translate(undef,$str)',
	ascii2gsm => 'ascii2gsm($str)'
});


1;

