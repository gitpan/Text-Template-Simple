#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

# <%- -%> -> chomp    (token directive takes precedence over global)
# <%~ ~%> -> no chomp (token directive takes precedence over global)
# <%^ ^%> -> collapse (token directive takes precedence over global)

TODO: {
    todo_skip("PRE/POST Chomp. Global PRE/POST chomp & collapse");
}
