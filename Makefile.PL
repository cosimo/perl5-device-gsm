# $Id: Makefile.PL,v 1.3 2002-04-05 22:26:40 cosimo Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'ABSTRACT_FROM' => 'Gsm.pm',
	'AUTHOR'    => 'Cosimo Streppone <cosimo@cpan.org>',
    'NAME'		=> 'Device::Gsm',
	'VERSION_FROM'	=> 'Gsm.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Device::Modem' => undef,
		'Device::SerialPort' => undef
	}
);

