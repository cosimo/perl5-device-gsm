# $Id: Makefile.PL,v 1.2 2002-04-03 19:07:04 cosimo Exp $

use ExtUtils::MakeMaker;

WriteMakefile(

	'AUTHOR'    => 'Cosimo Streppone <cosimo@cpan.org>',

    'NAME'		=> 'Device::Gsm',
    
	'VERSION_FROM'	=> 'Gsm.pm', # finds $VERSION

    'PREREQ_PM'		=> {
		'Device::Modem' => undef,
		'Device::SerialPort' => undef
	}

);

