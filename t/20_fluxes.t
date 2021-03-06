#!perl

use lib qw[ /home/bradc/development/perlmods ];

use strict;
use Test::More tests => 15;

require_ok('Astro::WaveBand');
require_ok('Astro::Flux');
require_ok('Astro::FluxColor');
require_ok('Astro::Fluxes');

my $flux1 = new Astro::Flux( 1, 'mag', new Astro::WaveBand( Filter => 'J' ) );
my $flux2 = new Astro::Flux( 4, 'mag', new Astro::WaveBand( Filter => 'H' ) );
my $color1 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'J' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 10 );
my $color2 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'H' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 13 );

my $fluxes = new Astro::Fluxes( $flux1, $color1, $color2 );

isa_ok( $fluxes, 'Astro::Fluxes' );
is( $fluxes->flux( waveband => new Astro::WaveBand( Filter => 'J' ) )->quantity('mag'), 1, 'Retrieval of non-derived magnitude');

is( $fluxes->flux( waveband => new Astro::WaveBand( Filter => 'H' ) ), undef, 'flux is undef when asking for a derived magnitude' );

is( $fluxes->flux( waveband => new Astro::WaveBand( Filter => 'H') , derived => 1 )->quantity('mag'), 4, 'Explicit retrieval of derived magnitude');

is( $fluxes->color( lower => new Astro::WaveBand( Filter => 'J' ), upper => new Astro::WaveBand( Filter => 'K' ) )->quantity, 10, 'Retrieval of stored color');

is( $fluxes->color( lower => new Astro::WaveBand( Filter => 'J' ), upper => new Astro::WaveBand( Filter => 'H' ) )->quantity, -3, 'Retrieval of derived color');

my $flux3 = new Astro::Flux( 3, 'mag', new Astro::WaveBand( Filter => 'R' ) );
$fluxes->pushfluxes( $flux3 );
is( $fluxes->flux( waveband => new Astro::WaveBand( Filter => 'R' ) )->quantity('mag'), 3, 'Retrieval of pushed magnitude');

# Now try a new fluxes object with measurements that aren't magnitudes.
my $iso_flux1 = new Astro::Flux( 1000, 'iso_flux', new Astro::WaveBand( Filter => 'J' ) );
my $iso_flux2 = new Astro::Flux( 2000, 'iso_flux', new Astro::WaveBand( Filter => 'K' ) );

my $iso_fluxes = new Astro::Fluxes( $iso_flux1, $iso_flux2 );
isa_ok( $iso_fluxes, 'Astro::Fluxes' );

# This should return undef because the flux() method defaults to 'mag' type.
my $ret_isoflux = $iso_fluxes->flux( waveband => new Astro::WaveBand( Filter => 'J' ) );
is( $ret_isoflux, undef, 'flux() method returns undef when no magnitude values are used in constructing Astro::Fluxes object' );

# Now use the type of 'iso_flux'.
$ret_isoflux = $iso_fluxes->flux( waveband => new Astro::WaveBand( Filter => 'J' ),
                                  type => 'iso_flux' );
isa_ok( $ret_isoflux, 'Astro::Flux' );
is( $ret_isoflux->quantity('iso_flux'), 1000, 'Returned isophotal J-band flux' );
