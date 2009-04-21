#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

TODO: {
    todo_skip("Test monolith => 1 & monolith => 0 with both static & dynamic inc");
}
