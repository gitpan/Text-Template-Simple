#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

TODO: {
    todo_skip("Test template file name access through \$0");
}