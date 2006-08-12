# $Id: 04syslog.t,v 1.5 2006-08-12 08:57:52 cosimo Exp $
#
# test syslog mechanism
#
use Test::More;
BEGIN { plan tests => 2 };

use Device::Gsm; 
ok(1);

SKIP: {

        if( $^O =~ /Win/i ) {
                skip('Syslog tests for Windows do not make sense', 1);
        }

        my $gsm = new Device::Gsm( log => 'syslog' );
        ok( $gsm->log->write('info', 'syslog test here') );

}
