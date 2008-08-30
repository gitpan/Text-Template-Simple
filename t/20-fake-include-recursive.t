#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(MAX_RECURSION);
use constant TEMPLATE => q{<%* t/data/test_var.tmpl %>};

my $t   = Text::Template::Simple->new();

sub test {
    my $rv = $t->compile( TEMPLATE );
    print "GOT: $rv\n";
    ok( $$ eq $rv, "Compile OK");
}

test() for 0..MAX_RECURSION+10;

ok( 1, "Fake recursive test did not fail");
