package Astro::Flux;

=head1 NAME

Astro::Flux - Class for handling astronomical flux quantities.

=head1 SYNOPSIS

  use Astro::Flux;

  $flux = new Astro::Flux( $quantity, $units, $waveband );

  $quantity = $flux->quantity('mag');

=head1 DESCRIPTION

Class for handling astronomical flux quantities. This class does
not currently support conversions from one flux type to another
(say, from magnitudes to Janskies) but may in the future.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

our $VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::Flux> object.

  $flux = new Astro::Flux( $quantity, $type, $waveband );

All three parameters must be defined. They are:

  quantity - numerical value for the flux
  type - type of flux. Can be any string.
  waveband - waveband for the given flux. Must be an C<Astro::WaveBand> object.

If any of the parameters are undefined, the constructor will throw
an error. If the waveband parameter is not an C<Astro::WaveBand> object,
the constructor will throw an error.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $quantity = shift;
  my $type = shift;
  my $waveband = shift;

  croak "Quantity must be defined"
    unless defined $quantity;

  croak "Type must be defined"
    unless defined $type;

  croak "Waveband must be an Astro::WaveBand object"
    unless UNIVERSAL::isa($waveband, "Astro::WaveBand");

  my $flux = {};

  $flux->{QUANTITY} = { $type => $quantity };
  $flux->{WAVEBAND} = $waveband;

  bless( $flux, $class );
  return $flux;

}

=back

=head2 Accessor Methods

=over 4

=item B<quantity>

Returns the quantity for a requested flux type.

  my $mag = $flux->quantity('mag');

No conversions are done between types. What you put in via the
constructor is all you can get out, so if you specify the type
to be 'magnitude' and you ask for a 'mag', this method will
throw an error.

=cut

sub quantity {
  my $self = shift;
  my $type = shift;

  return undef if ! defined $type;

  croak "Cannot translate between flux types"
    if ! defined( $self->{QUANTITY}->{$type} );

  return $self->{QUANTITY}->{$type};
}

=item B<waveband>

Returns the waveband for the given flux object.

  my $waveband = $flux->waveband;

Returns an C<Astro::WaveBand> object.

=cut

sub waveband {
  my $self = shift;

  return $self->{WAVEBAND};
}

=back

=head1 REVISION

 $Id$

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;