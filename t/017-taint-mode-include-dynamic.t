#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/dynamic.tts' );

print "OUTPUT: $out\n";

ok( $out eq confirm(), "Valid output from dynamic inclusion" );

sub confirm {
<<'CONFIRMED';
RAW 1: raw content <%= $$ %>
RAW 2: raw content <%= $$ %>
RAW 3: raw content <%= $$ %>
CONFIRMED
}
