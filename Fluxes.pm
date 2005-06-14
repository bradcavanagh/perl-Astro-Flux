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
use Misc::Quality;

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

      # Create an Misc::Quality object saying that these are derived
      # magnitudes.
      my $quality = new Misc::Quality( 'derived' => 1 );

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
  my $running_error = undef;
  foreach my $flux ( @{$self->{$key}} ) {
    if( defined( $flux->reference_waveband ) &&
        ( scalar( @{$self->{substr( $flux->reference_waveband->natural, 0, 1 )}} > 1 ) ||
          ${$self->{substr( $flux->reference_waveband->natural, 0, 1 ) }}[0]->reference_waveband != $waveband ) ) {
      $running_total += $flux->quantity('mag');
      $running_error += $flux->error('mag')*$flux->error('mag');
      $ref_flux = ${$self->{substr( $flux->reference_waveband->natural, 0, 1 ) }}[0];
      last;
    }
  }

  # If we have a reference flux, get the magnitude from that waveband and add
  # it to the running total.
  if( defined( $ref_flux ) ) {
    my $mag = $self->flux( waveband => $ref_flux->waveband, derived => 1 )->quantity('mag');
    my $err = $self->flux( waveband => $ref_flux->waveband, derived => 1 )->error('mag');
    $running_total += $mag;
    $running_error += $err if defined $err;
  }

  $running_error = sqrt( $running_error );
  
  # Form a flux object with the running total and the input waveband,
  # and return that.
  if( ! defined( $running_total ) ) {
    return undef;
  } else {
    my $number;
    if ( defined $running_error ) {
       $number = new Number::Uncertainty( Value => $running_total,
                                          Error => $running_error );
    } else {
       $number = $running_total;
    }
       					  
    my $returned_flux = new Astro::Flux( $number, 'mag', $waveband, 
                            quality => new Misc::Quality( derived => 1 ) );
			    
    return $returned_flux;			    
  }
  
}

=item B<color>

Returns the color for two requested wavebands.

my $color = $fluxes->color( upper => new Astro::WaveBand( Filter => 'H' ),
                            lower => new Astro::WaveBand( Filter => 'J' ) );

Arguments are passed as key-value pairs. The two mandatory named arguments are
'upper' and 'lower', denoting the upper (longer wavelength) and lower (shorter
wavelength) wavebands for the color. The value for either can be either an
C<Astro::WaveBand> object or a string that can be used to create a new
C<Astro::WaveBand> object via its Filter parameter.

The above example will return the H-K color.

=cut

sub color {
  my $self = shift;
  my %args = @_;

  my $result;

  if( ! defined( $args{'upper'} ) ) {
    croak "upper waveband argument must be passed to &Astro::Fluxes::color";
  }
  if( ! defined( $args{'lower'} ) ) {
    croak "lower waveband argument must be passed to &Astro::Fluxes::color";
  }

  my $upper = $args{'upper'};
  my $lower = $args{'lower'};

  # Upgrade the wavebands to proper Astro::WaveBand objects if necessary.
  if( ! UNIVERSAL::isa( $upper, "Astro::WaveBand" ) ) {
    $upper = new Astro::WaveBand( Filter => $upper );
  }
  if( ! UNIVERSAL::isa( $lower, "Astro::WaveBand" ) ) {
    $lower = new Astro::WaveBand( Filter => $lower );
  }

  # First, find out if we have an easy job. Check if the lower refers to
  # the upper, from which we can get the colour directly.
  my $upper_key = substr( $upper->natural, 0, 1 );
  my $lower_key = substr( $lower->natural, 0, 1 );
  use Data::Dumper;
  foreach my $flux ( @{$self->{$lower_key}} ) {
    if( defined( $flux->reference_waveband ) ) {
      my $ref_key = substr( $flux->reference_waveband->natural, 0, 1 );
      if( $ref_key eq $upper_key ) {
        return new Astro::FluxColor( lower => $lower,
                                     upper => $upper,
                                     quantity => $flux->quantity('mag') );
      }
    }
  }

  # So we're here. Maybe we can get magnitudes for the upper and lower wavebands.
  my $upper_mag = $self->flux( waveband => $upper, derived => 1 );
  my $lower_mag = $self->flux( waveband => $lower, derived => 1 );
  if( defined( $upper_mag ) && defined( $lower_mag ) ) {
    return new Astro::FluxColor( lower => $lower,
                                 upper => $upper,
                                 quantity => $lower_mag->quantity('mag') - $upper_mag->quantity('mag') );
  }

  # At this point I don't really know how to get a colour. If we're here
  # that means we have some kind of colour-colour relation that we might
  # be able to get the desired colour from...

  # Return undef in the meantime.
  return undef;

}


=item B<pushfluxes>

Push C<Astro::Flux> and C<Astro::FluxColor> object into the C<Astro::Fluxes>
object,

  $fluxes->pushfluxes( $flux1, $flux2, $color1 );

Any number of C<Astro::Flux> or C<Astro::FluxColor> objects can
be passed as arguments.

=cut

sub pushfluxes {
  my $self = shift;

  foreach my $arg ( @_ ) {
    if( UNIVERSAL::isa( $arg, "Astro::Flux" ) ) {
      my $key = substr( $arg->waveband->natural, 0, 1 );
     push @{$self->{$key}}, $arg;
    } elsif( UNIVERSAL::isa( $arg, "Astro::FluxColor" ) ) {

      # Create an Misc::Quality object saying that these are derived
      # magnitudes.
      my $quality = new Misc::Quality( 'derived' => 1 );

      # Create two flux objects, one for the lower and one for the upper.
      my $lower_flux = new Astro::Flux( $arg->quantity , 'mag', $arg->lower,
                                        quality => $quality,
                                        reference_waveband => $arg->upper );
      my $upper_flux = new Astro::Flux( -1.0 * $arg->quantity, 'mag', $arg->upper,
                                        quality => $quality,
                                        reference_waveband => $arg->lower );

      push @{$self->{substr( $lower_flux->waveband->natural, 0, 1 )}}, $lower_flux;
      push @{$self->{substr( $upper_flux->waveband->natural, 0, 1 )}}, $upper_flux;

    }
  }

  return $self;

}

=item B<allfluxes>

Returns an hash of all the C<Astro::Flux> objects contained in the
C<Astro::Fluxes> object,

  %fluxes = $fluxes->allfluxes();

=cut

sub allfluxes {
  my $self = shift;
   
  return %{$self};

}

=item B<fluxesbywaveband>

Returns an hash of all the C<Astro::Flux> objects contained in the
C<Astro::Fluxes> object,

  @fluxes = $fluxes->fluxesbywaveband(  waveband => 'J' );

=cut

sub fluxesbywaveband {
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
  return @{$self->{$key}};
}


=item B<whatwavebands>

Returns an array of the wavebands contained in the object

  @wavebands = $fluxes->whatwavebands( );

=cut

sub whatwavebands {
  my $self = shift;
  my %args = @_;

  my $result;

  my @wavebands;
  foreach my $key ( sort keys %{$self} ) {
     push @wavebands, $key;
  }   
  return @wavebands;
}

=back

=head1 REVISION

 $Id$

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 - 2005 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
