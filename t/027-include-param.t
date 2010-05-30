#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use File::Spec;

my $t = Text::Template::Simple->new();

my $got = $t->compile( File::Spec->catfile( qw( t data ), '027-dynamic.tts' ) );

is( $got, 'Dynamic: Perl ROCKS!', 'Dynamic include got params');
