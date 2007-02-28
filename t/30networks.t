# $Id: 30networks.t,v 1.2 2007-02-28 20:54:32 cosimo Exp $
# test pdu encoding/decoding functions for sms

use Test::More;
plan tests => 4;
use_ok('Device::Gsm::Networks');

is(
    Device::Gsm::Networks::name('22288'),
    'Wind Telecomunicazioni SpA',
    'network name decoding works'
);

is(
    Device::Gsm::Networks::name('222 88'),
    'Wind Telecomunicazioni SpA',
    'network name decoding works'
);

is(
    Device::Gsm::Networks::country('222'),
    'Italy',
    'country name decoding works'
);

