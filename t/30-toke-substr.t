#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

$SIG{__WARN__} = sub {
    chomp(my $m = shift);
    die "This thing must no generate a single warning, but it did: ->$m<-";
};

my $t = Text::Template::Simple->new();

ok( $t->compile(q/<%%>/) eq '', "Nothing" ); # test edge case
