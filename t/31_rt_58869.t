# Test decode/encode text7 

use Test::More;
plan tests => 1;
 
use Device::Gsm::Pdu;

my @case = (
    '1234567'
);

for (@case) {
    my $text = $_;

    # Roundtrip test
    is(
        $text,
        Device::Gsm::Pdu::decode_text7(
            Device::Gsm::Pdu::encode_text7($text)
        ),
        'Round trip text7 conversion of "' . $text . '"'
    );

}

