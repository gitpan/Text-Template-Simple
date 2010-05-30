#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(:all);

local $SIG{__WARN__} = sub {
    chomp(my $m = shift);
    fail "This thing must not generate a single warning, but it did: ->$m<-";
};

my $t = Text::Template::Simple->new();

ok( $t->compile(q/<%%>/) eq EMPTY_STRING, 'Nothing' ); # test edge case
