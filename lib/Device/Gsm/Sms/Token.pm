# $Id: Token.pm,v 1.1 2003-03-23 12:59:07 cosimo Exp $

package Sms::Token;

use strict;
use integer;
use Carp 'croak';

# Token possible states
use constant ERROR   => 0;
use constant ENCODED => 1;
use constant DECODED => 2;

#
# new token ( @data )
#
sub new {
	my($proto, $name, @data) = @_;
#	my $class = ref $proto || $proto;
	my %token = ( __name => $name, __data => \@data, __state => '' );

	# Dynamically load required token module
	eval { require "Device/Gsm/Sms/Token/$name.pm" };
	if( $@ ) {
		warn('cannot load Device::Gsm::Sms::Token::'.$name.' plug-in for decoding. Error: '.$@);
		return undef;
	}

	# Try "static blessing" =:-o and see if it works
	bless \%token, 'Sms::Token::'.$name;
}

#
# Get/set internal token data
#
sub data {
	my $self = shift;
	if( @_ ) {
		if( $_[0] eq undef ) {
			$self->{'__data'} = [];
		} else {
			$self->{'__data'} = [ @_ ];
		}
	}
	$self->{'__data'};
}

# Must be implemented in real token
sub decode {
	croak( 'decode() not implemented in token base class');
	return 0;
}

# Must be implemented in real token
sub encode {
	croak( 'encode() not implemented in token base class');
	return 0;
}

sub get {
	my($self, $info) = @_;
	return undef unless $info;

	return $self->{"_$info"};
}

sub name {
	my $self = shift;
	return $self->{'__name'};
}

sub set {
	my($self, $info, $newval) = @_;
	return undef unless $info;
	$newval = undef unless defined $newval;
	$self->{"_$info"} = $newval;
}

sub state {
	my $self = shift;
	return $self->{'__state'};
}

sub toString {
	my $self = shift;
	my $string;
	if( ref $self->{'__data'} eq 'ARRAY' ) {
		$string = join '', @{$self->{'__data'}};
	}
	return $string;
}

1;

