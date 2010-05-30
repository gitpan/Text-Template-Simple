#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/recursive.tts' );

my $pok = print $out, "\n";

ok( $out, 'Nasty recursive test did not fail' );
