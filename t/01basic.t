# $Id: 01basic.t,v 1.1 2002-04-03 19:13:35 cosimo Exp $

use strict;
use warnings;

use Test::More tests => 2;
use_ok 'Device::Gsm';

my $gsm = Device::Gsm->new();
ok $gsm;
