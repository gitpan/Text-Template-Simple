#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t   = Text::Template::Simple->new();
my $out = $t->compile( 't/data/interpolate.tts' );

print "OUTPUT($out)\n";

my $expect = confirm();

ok( $out           , "Interpolated dynamic & static include" );
ok( $out eq $expect, "Interpolated include has correct data: '$out' eq '$expect'" );

sub confirm {
<<"CONFIRMED";

Test: $^O
Test: <%= \$^O %>
Test: $^O
Test: <%= \$^O %>
CONFIRMED
}
