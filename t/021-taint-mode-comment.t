#!C:\Perl\bin\perl.exe -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use constant TEMPLATE => q{No comment<%#
This
is
a
multi-line
comment
which
will
be
ignored
%>};

my $t = Text::Template::Simple->new();

ok( $t->compile( TEMPLATE ) eq 'No comment', "Comment removed successfully");
