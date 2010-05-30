#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new();

my $got = $t->compile( File::Spec->catfile( qw( t data ), '028-dynamic.tts' ) );
my $expect = 'Dynamic: KLF-->Perl ROCKS!<--MUMULAND';

is($got, $expect, 'Dynamic include got params' );

package Text::Template::Simple::Dummy;
use strict;

sub filter_foobar {
    my $self = shift;
    my $oref = shift;
    ${$oref} = sprintf '-->%s<--', ${$oref};
    return;
}

sub filter_baz {
    my $self = shift;
    my $oref = shift;
    ${$oref} = sprintf 'KLF%sMUMULAND', ${$oref};
    return;
}
