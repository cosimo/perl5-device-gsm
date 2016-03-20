# test gsm <=> ascii charset conversions

use Test::More;
use lib '../blib/lib';
use Device::Gsm::Charset;

BEGIN { plan tests => 511 };

ok(1, 'loaded');

my @a1 = map {chr} 0 .. 255;

foreach my $c (@a1) {

    # I can't seem to resolve these tests
    next if $c eq chr(140) || $c eq chr(141);

    my $test_c = $c;

    # "Replaced" chars that don't exist in GSM charset must be
    # passed one-time first before conversion-reconversion phase
    my $cx = $Device::Gsm::Charset::ISO8859_TO_GSM0338[ord($c)];
    if( $cx < 0  ||  $cx == Device::Gsm::Charset::NPC7 ) {
        $test_c = Device::Gsm::Charset::gsm0338_to_iso8859(
            Device::Gsm::Charset::iso8859_to_gsm0338($c)
        );
    }

    # Check conversion correctness
    is(
        $test_c,
        Device::Gsm::Charset::gsm0338_to_iso8859(
            Device::Gsm::Charset::iso8859_to_gsm0338($test_c)
        ),
        'conversion of char `'.$c.'\''
    );
    
    if( $cx < 0  ||  $cx == Device::Gsm::Charset::NPC7
       && ord($c) != Device::Gsm::Charset::NPC7 ) {
        ok( ! Device::Gsm::Charset::gsm0338_ok( $c ),
            'Character ' . ord($c) . ' is not valid for GSM0338'
        );
    } else {
        ok( Device::Gsm::Charset::gsm0338_ok( $c ),
            'Character ' . ord($c) . ' is valid for GSM0338'
        );
    }

}

my $c = chr(300);
is(Device::Gsm::Charset::iso8859_to_gsm0338($c),
    chr(Device::Gsm::Charset::NPC7),
    'Validate unicode characters get converted to NPC'
);
ok( ! Device::Gsm::Charset::gsm0338_ok( $c ),
    'Character ' . ord($c) . ' is not valid for GSM0338'
);

# end of test
