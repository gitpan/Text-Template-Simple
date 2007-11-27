#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test::More;
BEGIN { plan tests => 2 }

use Text::Template::Simple;

my $t = Text::Template::Simple->new;

ok( $t->compile(q/<%!f%>/) eq '<%f%>', "Escaped delim 1" );
ok( $t->compile(q/<%!f>/)  eq '<%f>' , "Escaped delim 2" );

exit;

__END__
