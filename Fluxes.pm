package Astro::Fluxes;

=head1 NAME

Astro::Fluxes - Class for handling a collection of astronomical flux
quantities.

=head1 SYNOPSIS

  use Astro::Fluxes;

  $fluxes = new Astro::Fluxes( $flux1, $flux2, $color1 );

  my $flux = $fluxes->flux( waveband => $waveband );

=head1 DESCRIPTION

Class for handling a collection of astronomical flux quantities.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::Flux;
use Astro::Quality;

our $VERSION = '0.01';



=head1 METHODS

=head2 CONSTRUCTOR

=over 4

=item B<new>

Create a new instance of an C<Astro::Fluxes> object.

  $fluxes = new Astro::Fluxes( $flux1, $flux2, $color1 );

Any number of C<Astro::Flux> or C<Astro::FluxColor> objects can
be passed as arguments.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $fluxes = ();

  foreach my $arg ( @_ ) {
    if( UNIVERSAL::isa( $arg, "Astro::Flux" ) ) {
      my $key = substr( $arg->waveband->natural, 0, 1 );
      push @{$fluxes->{$key}}, $arg;
    } elsif( UNIVERSAL::isa( $arg, "Astro::FluxColor" ) ) {

      # Create an Astro::Quality object saying that these are derived
      # magnitudes.
      my $quality = new Astro::Quality( 'derived' => 1 );

      # Create two flux objects, one for the lower and one for the upper.
      my $lower_flux = new Astro::Flux( $arg->quantity , 'mag', $arg->lower,
                                        quality => $quality,
                                        reference_waveband => $arg->upper );
      my $upper_flux = new Astro::Flux( -1.0 * $arg->quantity, 'mag', $arg->upper,
                                        quality => $quality,
                                        reference_waveband => $arg->lower );

      push @{$fluxes->{substr( $lower_flux->waveband->natural, 0, 1 )}}, $lower_flux;
      push @{$fluxes->{substr( $upper_flux->waveband->natural, 0, 1 )}}, $upper_flux;

    }
  }

  bless( $fluxes, $class );

  return $fluxes;

}

=back

=head2 Accessor Methods

=over 4

=item B<flux>

Returns the flux for a requested waveband.

  my $flux = $fluxes->flux( waveband => 'J' );

Arguments are passed as key-value pairs. The sole mandatory named
argument is 'waveband'; its value can either be an C<Astro::WaveBand>
object or a string that can be used to create a new C<Astro::WaveBand>
via its Filter parameter.

Optional arguments are:

  derived - Whether or not to return fluxes that have been derived
    from colors. Defaults to false, so that derived fluxes will not
    be returned.

This method returns an C<Astro::Flux> object.

=cut

sub flux {
  my $self = shift;
  my %args = @_;

  my $result;

  if( ! defined( $args{'waveband'} ) ) {
    croak "waveband argument must be passed to &Astro::Fluxes::flux";
  }

  my $waveband = $args{'waveband'};
  my $derived = defined( $args{'derived'} ) ? $args{'derived'} : 0;

  if( ! UNIVERSAL::isa( $waveband, "Astro::WaveBand" ) ) {
# Upgrade to a proper Astro::WaveBand object.
    $waveband = new Astro::WaveBand( Filter => $waveband );
  }

  # The key is the first character in the waveband.
  my $key = substr( $waveband->natural, 0, 1 );

  # Check to see if we have a measured magnitude for this waveband.
  foreach my $flux ( @{$self->{$key}} ) {
    if( ! defined( $flux->reference_waveband ) ) {
      $result = $flux;
      last;
    }
  }

  return $result if defined $result;

  # Return right here with undef if $derived is false.
  return if ( ! $derived );

  # Get the reference waveband for the current flux such that the
  # reference waveband doesn't have only a pointer back to the current
  # one.
  my $ref_flux;
  my $running_total = undef;
  foreach my $flux ( @{$self->{$key}} ) {
    if( defined( $flux->reference_waveband ) &&
        ( scalar( @{$self->{substr( $flux->reference_waveband->natural, 0, 1 )}} > 1 ) ||
          ${$self->{substr( $flux->reference_waveband->natural, 0, 1 ) }}[0]->reference_waveband != $waveband ) ) {
      $running_total += $flux->quantity('mag');
      $ref_flux = ${$self->{substr( $flux->reference_waveband->natural, 0, 1 ) }}[0];
      last;
    }
  }

  # If we have a reference flux, get the magnitude from that waveband and add
  # it to the running total.
  if( defined( $ref_flux ) ) {
    my $mag = $self->flux( waveband => $ref_flux->waveband, derived => 1 )->quantity('mag');
    $running_total += $mag;
  }

  # Form a flux object with the running total and the input waveband,
  # and return that.
  if( ! defined( $running_total ) ) {
    return undef;
  } else {
    return new Astro::Flux( $running_total, 'mag', $waveband, quality => new Astro::Quality( derived => 1 ) );
  }
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
