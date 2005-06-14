package Astro::FluxColor;

=head1 NAME

Astro::FluxColor - Class for handling astronomical color quantities.

=head1 SYNOPSIS

use Astro::FluxColor;

  $color = new Astro::FluxColor( lower => $lower_waveband,
                                 upper => $upper_waveband,
                                 quantity => $quantity );

  $quantity = $color->quantity;

=head1 DESCRIPTION

Class for handling astronomical color quantities.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::WaveBand;
use Number::Uncertainty;

our $VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::FluxColor> object.

$color = new Astro::FluxColor( lower => $lower_waveband,
                               upper => $upper_waveband,
                               quantity => $quantity );

The three named parameters are mandatory. F<lower> and F<upper>
denote the lower and upper wavebands for the colour, and
must be C<Astro::WaveBand> objects. F<quantity> is a numerical
value in magnitudes.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my %args = @_;

  if( ! defined( $args{'lower'} ) ) {
    croak "Lower waveband must be defined";
  } elsif( ! UNIVERSAL::isa( $args{'lower'}, "Astro::WaveBand" ) ) {
    croak "Lower waveband must be an Astro::WaveBand object";
  }

  if( ! defined( $args{'upper'} ) ) {
    croak "Upper waveband must be defined";
  } elsif( ! UNIVERSAL::isa( $args{'upper'}, "Astro::WaveBand" ) ) {
    croak "Upper waveband must be an Astro::WaveBand object";
  }

  my $quantity;
  if( ! defined( $args{'quantity'} ) ) {
    croak "Color quantity must be defined";
  } elsif ( ! UNIVERSAL::isa($args{'quantity'}, "Number::Uncertainy" ) ) {
     $quantity = new Number::Uncertainty( Value => $args{'quantity'} );    
  } else {
     $quantity = $args{'quantity'};
  }
  my $color = {};

  $color->{LOWER} = $args{'lower'};
  $color->{UPPER} = $args{'upper'};
  $color->{QUANTITY} = $quantity;

  bless( $color, $class );
  return $color;

}

=back

=head2 Accessor Methods

=over 4

=item B<quantity>

Returns the actual color value.

  my $value = $color->quantity;

There are no parameters.

=cut

sub quantity {
  my $self = shift;

  my $number = $self->{QUANTITY};
  my $value = $number->value();
  return $value;
}

=item B<error>

Returns the actual uncertainty in the cerror.

  my $e = $color->error;

There are no parameters.

=cut

sub error {
  my $self = shift;

  my $number = $self->{QUANTITY};
  my $error = $number->error();
  return $error;
}

=item B<lower>

Returns the lower waveband.

  my $lower = $color->lower;

There are no parameters. An C<Astro::WaveBand> object is returned.

=cut

sub lower {
  my $self = shift;
  return $self->{LOWER};
}

=item B<upper>

Returns the upper waveband.

  my $upper = $color->upper;

There are no parameters. An C<Astro::WaveBand> object is returned.

=cut

sub upper {
  my $self = shift;
  return $self->{UPPER};
}

=back

=head1 REVISION

  $Id$

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
