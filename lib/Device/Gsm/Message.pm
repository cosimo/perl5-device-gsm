# Device::Gsm::Message - SMS Message class (in PDU format)
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
# $Id: Message.pm,v 1.2 2002-09-25 22:07:42 cosimo Exp $

package Device::Gsm::Message;
use strict;
use Device::Gsm::Pdu;

#
# new(
#     header => '+CMGL: .....',
#     pdu => '[encoded pdu string]'
# )
#
# creates message object
# 
sub new {
	my($proto, %opt) = @_;
	my $class = ref $proto || $proto;

	# Create new message object
	my $self = {};
	$self->{'options'} = \%opt;

	return undef unless( exists $opt{'header'} && exists $opt{'pdu'} );

    # Check for valid msg header
	if( $opt{'header'} =~ /\+CMGL:\s*(\d+),(\d+),(\d*),(\d+)/ ) {
		$self->{'index'}  = $1;
		$self->{'type'}   = $2;
		$self->{'xxx'}    = $3;   # XXX
		$self->{'length'} = $4;
			
		$self->{'pdu'}    = $opt{'pdu'};
#		$self->{'decoded'}= Device::Gsm::Pdu::decode_text7( $opt{'pdu'} );

	} else {

		# Warning: could not parse message header
		undef $self;

	}

	bless $self, $class if ref $self;
	return $self;
}

#
# type(): returns message type in ascii readable format
#
{
	# XXX
	my @types = ( 'UNKNOWN', 'REC UNREAD', 'REC READ', 'SENT UNREAD', 'SENT READ' );

sub type () {
	my $self = shift;
	return $types[ defined $self->{'type'} ? $self->{'type'} : 0 ];
}

}

sub sender () {
	my $self = shift;
	$self->{'sender'};
}

=head1 NAME

Device::Gsm::Message - SMS messages internal class 

=head1 WARNING

   This is C<ALPHA> software, still needs a lot of testing, so
   so use it at your own risk and without C<ANY> warranty! Have fun.

=head1 SYNOPSIS

  #
  # This is an internal class, so you should not have
  # need to use it directly, but ..
  #

  use Device::Gsm::Message;

  my $msg = new Device::Gsm::Message(
      header => '+CMGL: ...',
      pdu => `[encoded pdu data]'
  );

  print $msg->recipient() , "\n";
  print $msg->sender()    , "\n";
  print $msg->content()   , "\n";
  print $msg->time()      , "\n";
  print $msg->type()      , "\n";


=head1 DESCRIPTION

C<Device::Gsm::Message> class implements very basic SMS message object,
that can be used to decode C<+CMGL> GSM command response to build a more
friendly high-level object.

Please be kind to the universe and contact me if you have troubles or you are
interested in this.

=head1 REQUIRES

=over 4

=item * 

Device::Gsm

=back

=head1 EXPORTS

None

=head1 COPYRIGHT

Device::Gsm::Message - SMS Message class (in PDU format)
Copyright (C) 2002 Cosimo Streppone, cosimo@cpan.org

This program is free software; you can redistribute it and/or modify
it only under the terms of Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Perl licensing terms for details.

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

L<Device::Gsm>, perl(1)

=cut

