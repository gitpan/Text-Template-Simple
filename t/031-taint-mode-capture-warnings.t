#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use constant PERL_55     =>              $] < 5.006;
use constant PERL_56     => ! PERL_55 && $] < 5.007;
use constant PERL_LEGACY => PERL_55 || PERL_56;
use Text::Template::Simple;

my $t = Text::Template::Simple->new(
            capture_warnings => 1,
        );

my $got = $t->compile(q/Warn<%= my $r %>this/);
my $want = PERL_55
         ? "Warnthis[warning] Use of uninitialized value at <ANON> line 1.\n"
         : "Warnthis[warning] Use of uninitialized value in concatenation (.) or string at <ANON> line 1.\n"
         ;

is( $got, $want, "Warning captured" );
