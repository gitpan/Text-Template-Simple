#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

#$t->DEBUG(10);

my $got = $t->compile( 't/data/shared-var.tts' );

my $expected = <<'WANTED';
Foo: 42
$bar before: 123
$bar is not shared and not defined
Foo is 42
$bar after: I love Text::Template::Simple
WANTED

chomp $expected;

is( $got, $expected, 'Shared variables seem to work as intended');
