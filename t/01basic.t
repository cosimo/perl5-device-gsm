# $Id: 01basic.t,v 1.1 2002-04-03 19:13:35 cosimo Exp $

use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use Device::Gsm;
$loaded = 1;
ok(1);

my $gsm = Device::Gsm->new();
ok($gsm);
