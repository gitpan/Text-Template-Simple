#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use File::Temp qw( tempdir );
use Data::Dumper;
use constant PERL_55     =>              $] < 5.006;
use constant PERL_56     => ! PERL_55 && $] < 5.007;
use constant PERL_LEGACY => PERL_55 || PERL_56;
use constant IS_TAINT    => __PACKAGE__->can('TAINTMODE');
use constant SKIP_AMOUNT => 15;
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(:all);

# ref: http://rt.cpan.org/Public/Bug/Display.html?id=45885
for my $path ( qw( TEMP TMP ) ) {
    last if ! IS_TAINT || ! PERL_LEGACY;
    next if ! $ENV{ $path }; # this is just a test you know :p
    $ENV{ $path } = $1 if $ENV{ $path } =~ m{\A (.*) \z}xms;
}

SKIP: {
    skip(
         'Skipping dumper tests that need Deparse(). '
        .'You need to upgrade Data::Dumper to run these',
        SKIP_AMOUNT
    ) if ! Data::Dumper->can('Deparse');

    my $TEMPDIR = tempdir( CLEANUP => PERL_LEGACY ? 0 : 1 );

    my $tm = Text::Template::Simple->new(
               cache => 1,
            );

    my $td = Text::Template::Simple->new(
               cache     => 1,
               cache_dir => $TEMPDIR,
            );

    run( $_ ) for $tm, $td;
}

sub run {
    my $t      = shift;
    my $raw    = $t->compile( template() );
    my $struct = $t->cache->dumper( 'structure' );
    my $pok;
    $pok = print $struct;
    ok( $struct, 'Got the structure' );

    my $struct2 = $t->cache->dumper( structure => { varname => 'ABC' } );
    $pok = print $struct2;
    like( $struct2, qr{ \$ABC \s+ = \s+ }xms,
          'Got the structure with the specified name' );

    my $struct3 = $t->cache->dumper( structure => { no_deparse => 1 } );
    $pok = print $struct3;
    ok( $struct3, 'Got the structure without deparse' );

    my $ids = $t->cache->dumper( 'ids' );
    $pok = print $ids;
    ok( $ids, 'Got the ids' );

    my $ids2 = $t->cache->dumper( ids => { varname => 'XYZ' } );
    $pok = print $ids2;
    like( $ids2, qr{ \$XYZ \s+ = \s+ }xms,
          'Got the ids with the specified name' );

    my $type = $t->cache->type;
    like( $type, qr{ DISK | MEMORY | OFF }xms, "Cache type ($type) is OK" );

    #to test or not?
    #hit
    #populate

    SKIP: {
        skip('Cache is disabled') if $type eq 'OFF';

        if ( $type eq 'MEMORY' ) {
            my $ok = eval { require Devel::Size; 1; };
            skip('Devel::Size not installed') if $@ || ! $ok;
            # RT#14849 was fixed in this *unofficial* release
            skip('Your Devel::Size is too old and has a known *serious* bug')
                if Devel::Size->VERSION < DEVEL_SIZE_VERSION;
        }

        my $size = $t->cache->size;

        if ( $type eq 'MEMORY' && ! defined $size ) {
            skip(q{We don't seem to have Devel::Size to calculate memcache});
        }

        ok( $size > 0, "We could call size( $size bytes )" );

        $t->cache->reset;

        my $before = $size;
        $size = $t->cache->size;
        if ( $type eq 'MEMORY' ) {
           ok( $size < $before / 2, "Cache size shrinked after reset: $size" );
        }
        else {
           ok( $size == 0, "Cache size is zero after reset: $size" );
        }
    }
    return;
}

sub template {
    return <<'TEMPLATE';
Time now: <%=scalar localtime 1219952008 %>
TEMPLATE
}
