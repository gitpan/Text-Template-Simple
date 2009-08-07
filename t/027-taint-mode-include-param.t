#!C:\Perl\bin\perl.exe -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use File::Spec;
use constant FILE => File::Spec->catfile( qw( t data ), '027-dynamic.tts' );
my $t = Text::Template::Simple->new();

ok($t->compile( FILE ) eq 'Dynamic: Perl ROCKS!', "Dynamic include got params");
