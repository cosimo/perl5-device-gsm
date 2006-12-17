# $Id: 30networks.t,v 1.1 2006-12-17 09:00:38 cosimo Exp $
# test pdu encoding/decoding functions for sms

use Test::More;
plan tests => 3;
use_ok('Device::Gsm::Networks');

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

