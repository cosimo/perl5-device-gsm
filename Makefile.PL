# $Id: Makefile.PL,v 1.7 2004-05-25 20:52:40 cosimix Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'ABSTRACT_FROM' => 'Gsm.pm',
	'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>',
	'NAME'          => 'Device::Gsm',
	'VERSION_FROM'  => 'Gsm.pm', # finds $VERSION
	'PREREQ_PM'     => {
                'Test::More'    => 0,
		'Device::Modem' => 0,
		( $^O =~ /Win/i
			? ( 'Win32::SerialPort' => 0 )
			: ( 'Device::SerialPort'=> 0 )
		)
	}
);

