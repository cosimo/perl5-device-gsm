# $Id: Makefile.PL,v 1.8 2006-04-20 20:11:00 cosimo Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'ABSTRACT_FROM' => 'Gsm.pm',
	'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>',
	'NAME'          => 'Device::Gsm',
	'VERSION_FROM'  => 'Gsm.pm', # finds $VERSION
	'PREREQ_PM'     => {
		'Test::More'    => 0,
		'Device::Modem' => 1.47,
		( $^O =~ /Win/i
			? ( 'Win32::SerialPort' => 0 )
			: ( 'Device::SerialPort'=> 0 )
		)
	},
    'META_MERGE' => {
        resources => {
            repository => 'git://github.com/cosimo/perl5-device-gsm.git',
            bugtracker => 'mailto:bug-device-gsm@rt.cpan.org',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
);

