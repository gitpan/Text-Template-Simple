#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $TEMPLATE = <<'COMMENT';
No comment<%#
This
is
a
multi-line
comment
which
will
be
ignored
%>
COMMENT

chomp $TEMPLATE;

my $t = Text::Template::Simple->new();

is( $t->compile( $TEMPLATE ), 'No comment', 'Comment removed successfully' );
