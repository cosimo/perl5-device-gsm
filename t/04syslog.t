# $Id: 04syslog.t,v 1.1 2002-04-03 20:59:13 cosimo Exp $
#
# test syslog mechanism
#
use Test;
BEGIN { plan tests => 2 };

use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0', log => 'syslog' );

ok( $gsm->log->write('syslog test here') );

