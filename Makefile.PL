# $Id: Makefile.PL,v 1.4 2002-04-08 22:18:46 cosimo Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'ABSTRACT_FROM' => 'Gsm.pm',
	'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>',
	'NAME'          => 'Device::Gsm',
	'VERSION_FROM'  => 'Gsm.pm', # finds $VERSION
	'PREREQ_PM'     => {
		'Device::Modem'      => undef,
		'Device::SerialPort' => undef
	}
);

