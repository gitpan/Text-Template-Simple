#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

my $template = <<'EMPTY';
<%+ t/data/empty.tts -%>
<%* t/data/empty.tts -%>
EMPTY

my $rv;
eval {
   $rv = $t->compile( $template );
};

is( $@,  '', 'Empty includes (static+dynamic) did not die' );
is( $rv, '', 'Empty includes (static+dynamic) returned empty string' );
