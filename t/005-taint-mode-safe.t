#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
# Using Safe templates (tricky)
# SEE ALSO: t/lib/My.pm
use strict;
use lib qw(t/lib);
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new( safe => 1 );

my $tmpl = q(<% my $name = shift %>Hello <%= $name %>, you are safe!);

my $out = $t->compile( $tmpl, [ "Burak" ] );

ok( $out                                 , "Got compiled output" );
ok( $out eq q{Hello Burak, you are safe!}, "Output is correct"   );

print $out, "\n";
