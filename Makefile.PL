# $Id: Makefile.PL,v 1.6 2002-09-03 21:25:47 cosimo Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'ABSTRACT_FROM' => 'Gsm.pm',
	'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>',
	'NAME'          => 'Device::Gsm',
	'VERSION_FROM'  => 'Gsm.pm', # finds $VERSION
	'PREREQ_PM'     => {
		'Device::Modem' => 0,
		( $^O =~ /Win/i
			? ( 'Win32::SerialPort' => 0 )
			: ( 'Device::SerialPort'=> 0 )
		)
	}
);

