#!/usr/bin/env perl -w
# Extending Text::Template::Simple with functions and globals
# SEE ALSO: t/lib/My.pm
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use Data::Dumper;
use My;

ok($My::VERSION, 'My::VERSION defined');

my $pok;

$pok = print "Extending Text::Template::Simple with My v$My::VERSION\n";

my $t = Text::Template::Simple->new;

my $tmpl = <<'THE_TEMPLATE';
<% my $url = shift %>
Function call  : <%=      hello  "Burak"          %>
Global variable: X is <%= $GLOBAL{X}              %>
THE_TEMPLATE

my $out = $t->compile( $tmpl, [ 'http://search.cpan.org/' ] );

ok( $out, 'Got output' );

$pok = print $out;

my $d = Data::Dumper->new(
           [ \%Text::Template::Simple::Dummy:: ],
           [ '*SYMBOL'                         ]
        );

$pok = print "\nDumping template namespace symbol table ...\n";
$pok = print $d->Dump;
