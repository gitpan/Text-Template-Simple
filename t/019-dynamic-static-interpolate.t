#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/interpolate.tts' );

my $pok = print "OUTPUT($out)\n";

my $expect = confirm();

ok( $out           , 'Interpolated dynamic & static include' );
ok( $out eq $expect, "Interpolated include has correct data: '$out' eq '$expect'" );

sub confirm {
    return <<"CONFIRMED";

Test: $^O
Test: <%= \$^O %>
Test: $^O
Test: <%= \$^O %>
CONFIRMED
}
