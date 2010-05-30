#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(MAX_RECURSION);
use constant RECURSE_LIMIT => MAX_RECURSION + 10;

my $t = Text::Template::Simple->new();

sub test {
    my $rv  = $t->compile( q{<%* t/data/test_var.tts %>} );
    my $pok = print "GOT: $rv\n";
    return is( $$, $rv, 'Compile OK' );
}

test() for 0..RECURSE_LIMIT;

ok( 1, 'Fake recursive test did not fail' );
