#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Cwd;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/static.tts' );

my $pok = print "OUTPUT: $out\n";

my $confirm = confirm();

ok( $out eq $confirm, "Valid output from static inclusion: '$out' eq '$confirm'" );

sub confirm {
    return <<'CONFIRMED';
RAW 1: raw content <%= $$ %>
RAW 2: raw content <%= $$ %>
RAW 3: raw content <%= $$ %>
CONFIRMED
}

