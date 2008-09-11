#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new(
           include_paths => [  ],
        );

TODO: {
    todo_skip("Test include_paths for both normal compilation & includes (static + dynamic)");
}
