#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $raw     = q~<? my $x = 2008; ?>Foo: <?= $x ?><?# comment ?>~;
my $static  = q~<?+ t/data/raw.txt ?>~;
my $dynamic = q~<?* t/data/dynamic_delim.tts ?>~;
my @delims  = qw/ <? ?> /;
my $t       = Text::Template::Simple->new( delimiters => [ @delims ] );

ok( $t->compile( $raw    )  eq 'Foo: 2008'  , "CODE/CAPTURE/COMMENT: Delimiters changed into @delims");
ok( $t->compile( $static )  eq 'raw content <%= $$ %>', "STATIC: Delimiters changed into @delims");
ok( $t->compile( $dynamic ) eq 'Dynamic: 42', "DYNAMIC: Delimiters changed into @delims");
