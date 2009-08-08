#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );

use Text::Template::Simple;

my $t = Text::Template::Simple->new;

ok( $t->compile(q/<%!f%>/) eq '<%f%>', "Escaped delim 1" );
ok( $t->compile(q/<%!f>/)  eq '<%f>' , "Escaped delim 2" );
