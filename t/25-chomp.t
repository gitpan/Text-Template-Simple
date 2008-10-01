#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );

use Text::Template::Simple;
use Text::Template::Simple::Constants qw( :chomp );

my $t = Text::Template::Simple->new;

# some dumb test for now
my $test = <<'THIS';
BU
<%=~ 'R' ~%>
AK
<%- my $z -%>
FF
THIS

my $expect = <<'THIS';
BU R AKFF
THIS

my $got = $t->compile( $test );

ok( $got eq $expect, "'$got' eq '$expect'" );
