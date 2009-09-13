#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

$SIG{__WARN__} = sub {
    chomp(my $m = shift);
    fail "This thing must not generate a single warning, but it did: ->$m<-";
};

my $t = Text::Template::Simple->new();

ok( $t->compile(q/<%%>/) eq '', "Nothing" ); # test edge case
