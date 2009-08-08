#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

my $got = $t->compile(<<'THIS');
<% for (1..4) {%>
   <%|- FILTER: foo;TEST-%>
<% } %>
THIS

my $expect = "!!!TEST!!!\n" x 4;

is( $got, "$expect\n", "Filtered block with loop around it");

package Text::Template::Simple::Dummy;
use strict;

sub filter_foo {
    my $self = shift;
    my $oref = shift;
    $$oref   = "!!!$$oref!!!\n";
    return;
}
