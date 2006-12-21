#!/usr/bin/env perl -w
# Using Safe templates (tricky)
# SEE ALSO: t/lib/My.pm
use strict;
use lib qw(t/lib);
use Test;
BEGIN { plan tests => 2 }

use Text::Template::Simple; 

my $t = Text::Template::Simple->new(safe => 1);

my $tmpl = q(<% my $name = shift %>Hello <%= $name %>, you are safe!);

my $out;

ok( $out = $t->compile( $tmpl, [ "Burak" ] ) );
ok( $out eq q{Hello Burak, you are safe!}    );

print $out;

exit;

__END__
