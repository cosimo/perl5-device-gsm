# $Id: 04syslog.t,v 1.3 2002-09-03 20:44:53 cosimo Exp $
#
# test syslog mechanism
#
use Test;
BEGIN { plan tests => 2 };

use Device::Gsm; 
ok(1);

my $gsm = new Device::Gsm( log => 'syslog' );
ok( $gsm->log->write('info', 'syslog test here') );

