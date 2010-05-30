#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/dynamic.tts' );

my $pok = print "OUTPUT: $out\n";

ok( $out eq confirm(), 'Valid output from dynamic inclusion' );

sub confirm {
    return <<'CONFIRMED';
RAW 1: raw content <%= $$ %>
RAW 2: raw content <%= $$ %>
RAW 3: raw content <%= $$ %>
CONFIRMED
}
