#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use constant FILE => File::Spec->catfile( qw( t data ), '028-dynamic.tts' );

my $t = Text::Template::Simple->new();

my $got = $t->compile( FILE );
my $expect = 'Dynamic: KLF-->Perl ROCKS!<--MUMULAND';

ok($got eq $expect, "Dynamic include got params");

package Text::Template::Simple::Dummy;
use strict;

sub filter_FooBar {
    my $self = shift;
    my $oref = shift;
    $$oref   = "-->$$oref<--";
    return;
}

sub filter_Baz {
    my $self = shift;
    my $oref = shift;
    $$oref   = "KLF".$$oref."MUMULAND";
    return;
}
