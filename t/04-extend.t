#!/usr/bin/env perl -w
# Extending Text::Template::Simple with functions and globals
# SEE ALSO: t/lib/My.pm
use strict;
use lib qw(t/lib lib);
use Test;
BEGIN { plan tests => 2 }

use Text::Template::Simple; 
use My;
use Data::Dumper;

ok($My::VERSION);

print "Extending Text::Template::Simple with My v$My::VERSION\n";

my $t = Text::Template::Simple->new;

my $tmpl = <<'THE_TEMPLATE';
<% my $url = shift %>
Function call  : <%=      hello  "Burak"          %>
Global variable: X is <%= $GLOBAL{X}              %>
THE_TEMPLATE

my $out;

ok( $out = $t->compile( $tmpl, [ "http://search.cpan.org/" ] ) );

print $out;
my $d = Data::Dumper->new(
           [ \%Text::Template::Simple::Dummy:: ],
           [ '*SYMBOL'                         ]
        );
print "\nDumping template namespace symbol table ...\n";
print $d->Dump;

exit;

__END__
