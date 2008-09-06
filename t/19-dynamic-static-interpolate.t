#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/interpolate.tts' );

print "OUTPUT($out)\n";

ok( $out             , "Interpolated dynamic & static include" );
ok( $out eq confirm(), "Interpolated include has correct data" );

sub confirm {
<<"CONFIRMED";

Test: $^O
Test: <%= \$^O %>
Test: $^O
Test: <%= \$^O %>
CONFIRMED
}
