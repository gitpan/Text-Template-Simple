#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use File::Temp qw( tempdir );

use Text::Template::Simple;

my $TEMPDIR = tempdir( CLEANUP => 1 );

my $tm = Text::Template::Simple->new(
           cache => 1,
        );

my $td = Text::Template::Simple->new(
           cache     => 1,
           cache_dir => $TEMPDIR,
        );

run( $_ ) for $tm, $td;

sub run {
    my $t = shift;
    my $raw = $t->compile( template() );
    my $struct = $t->cache->dumper( 'structure' );
    print $struct;
    ok( $struct, "Got the structure");

    my $struct2 = $t->cache->dumper( structure => { varname => 'ABC' } );
    print $struct2;
    ok( $struct2 =~ m{ \$ABC \s+ = \s+ }xms, "Got the structure with the specified name");

    my $struct3 = $t->cache->dumper( structure => { no_deparse => 1 } );
    print $struct3;
    ok( $struct3, "Got the structure without deparse");

    my $ids = $t->cache->dumper( 'ids' );
    print $ids;
    ok( $ids, "Got the ids");

    my $ids2 = $t->cache->dumper( ids => { varname => 'XYZ' } );
    print $ids2;
    ok( $ids2 =~ m{ \$XYZ \s+ = \s+ }xms, "Got the ids with the specified name");

    my $type = $t->cache->type;
    ok( $type =~ m{ DISK | MEMORY | OFF }xms, "Cache type ($type) is OK" );

    #to test or not?
    #hit
    #populate

    SKIP: {
        if ( $type ne 'DISK' ) {
            skip("Disable below tests for memcache until someone fixes RT#14849 for Devel::Size");
        }

        my $size = $t->cache->size;

        if ( $type eq 'MEMORY' && ! defined $size ) {
            skip("We don't seem to have Devel::Size to calculate memcache");
        }

        ok( $size > 0, "We could call size( $size bytes )" );

        $t->cache->reset;
        $size = $t->cache->size;
        ok( $size == 0, "Cache size is zero after reset" );
    }
}

sub template {
<<'TEMPLATE';
Time now: <%=scalar localtime time %>
TEMPLATE
}
