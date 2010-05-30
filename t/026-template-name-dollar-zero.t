#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

my $got      = $t->compile( 't/data/tname_main.tts' );
my $expected = 't/data/tname_main.tts & t/data/tname_sub.tts';

is( $got, $expected, 'Template names are accessible via dollar zero' );
