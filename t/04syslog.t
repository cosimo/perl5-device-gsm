# $Id: 04syslog.t,v 1.2 2002-04-03 21:41:18 cosimo Exp $
#
# test syslog mechanism
#
use Test;
BEGIN { plan tests => 2 };

use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( port => '/dev/ttyS0', log => 'syslog' );

ok( $gsm->log->write('info', 'syslog test here') );

