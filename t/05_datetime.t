#!perl

use strict;
use Test::More tests => 7;
use DateTime;

require_ok('Astro::WaveBand');
require_ok('Astro::Flux');


my $flux = new Astro::Flux( -1, 'mag',
			    new Astro::WaveBand( Filter => 'J' ),
			    datetime => DateTime->now() );

isa_ok( $flux, 'Astro::Flux' );

is( $flux->quantity('mag'), -1, 'Retrieve flux');

my $wb = $flux->waveband;
my $dt = $flux->datetime;
isa_ok( $wb, "Astro::WaveBand");
isa_ok( $dt, "DateTime");
is( $wb->filter, 'J', "compare filter");
