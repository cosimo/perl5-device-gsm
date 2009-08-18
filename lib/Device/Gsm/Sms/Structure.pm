# Device::Gsm::Sms::Structure - SMS messages structure class
# Copyright (C) 2002 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# $Id$

package Device::Gsm::Sms;

use strict;
use integer;

use Device::Gsm::Sms;
use Device::Gsm::Sms::Token;

use Device::Gsm::Sms::Token::SCA;
use Device::Gsm::Sms::Token::PDUTYPE;

#
# Inspect structure of SMS
# This varies with sms type (deliver or submit)
#
sub structure {
	my $self = shift;
	my @struct;

	if( $self->type() == SMS_DELIVER ) {
		# UD takes UDL + UD automatically
		@struct = qw/SCA PDUTYPE OA PID DCS SCTS UD/;
	} elsif( $self->type() == SMS_SUBMIT ) {
		@struct = qw/SCA PDUTYPE MR DA PID DCS VP UD/;
	}

	return @struct;
}


1;
