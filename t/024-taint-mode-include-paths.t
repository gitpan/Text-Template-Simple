#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use File::Spec;

my $t = Text::Template::Simple->new;
my $i = Text::Template::Simple->new(
           include_paths => [ qw( t/data/path1   t/data/path2 ) ],
        );

my $i_got_1 = $i->compile("test1.tts");
my $i_got_2 = $i->compile("test2.tts");

my $t_got_1 = $t->compile("test1.tts");
my $t_got_2 = $t->compile("test2.tts");

my $tf_got_1 = eval { $t->compile([ FILE => "test1.tts"]); } || $@;
my $tf_got_2 = eval { $t->compile([ FILE => "test2.tts"]); } || $@;

my $canon = File::Spec->canonpath( "t/data/path2/test3.tts" );

ok($i_got_1 eq 'test1: test1.tts', "Include path successful for test1");
ok($i_got_2 eq "test2: test2.tts - dynamic $canon - static "
              .'<%= $0 %>', "Include path/dynamic/static successful for test1:"
              ."'$i_got_2'");

ok($t_got_1 eq 'test1.tts', "First test: Parameter interpreted as string");
ok($t_got_2 eq 'test2.tts', "Second test: Parameter interpreted as string");

my $c = "code died since file does not exists and include_paths unset";

like($tf_got_1, qr/Error opening \'test1.tts\' for reading/, "First test: $c");
like($tf_got_2, qr/Error opening \'test2.tts\' for reading/, "Second test: $c");
