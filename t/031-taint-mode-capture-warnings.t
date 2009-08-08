#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new(
            capture_warnings => 1,
        );

my $got = $t->compile(q/Warn<%= my $r %>this/);
my $want = "Warnthis[warning] Use of uninitialized value in concatenation (.) or string at <ANON> line 1.\n";

ok( $got eq $want, "Warning captured: '$got' eq '$want'" );
