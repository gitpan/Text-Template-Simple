#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use File::Temp qw( tempdir );
use constant template => q(Time now: <%=scalar localtime time %>);

use Text::Template::Simple;

my $TEMPDIR = tempdir( CLEANUP => 1 );

my $t = Text::Template::Simple->new(
           cache     => 1,
           cache_dir => $TEMPDIR,
        );

my $raw1 = $t->compile( template() );
ok( $t->cache->has( data => template()        ), "Run 1: Cache has DATA" );
ok( $t->cache->has( id   => $t->cache->id     ), "Run 1: Cache has ID"   );
my $raw2 = $t->compile( template() );
ok( $t->cache->has( data => template()        ), "Run 2: Cache has DATA" );
ok( $t->cache->has( id   => $t->cache->id     ), "Run 2: Cache has ID"   );

my $raw3 = $t->compile( template(), undef, { id => "12_cache_disk_t" } );
ok( $t->cache->has( data => template()        ), "Run 3: Cache has DATA" );
ok( $t->cache->has( id   => "12_cache_disk_t" ), "Run 3: Cache has ID"   );
ok( $t->cache->id eq "12_cache_disk_t", "Cache ID OK");

ok( $raw1 eq $raw2, "RAW1 EQ RAW2 - '$raw1' eq '$raw2'" );
ok( $raw2 eq $raw3, "RAW2 EQ RAW3 - '$raw2' eq '$raw3'" );

ok( $t->cache->type eq 'DISK', "Correct cache type is set" );
