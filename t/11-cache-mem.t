#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
use constant TEMPLATE => 'Time now: <%=scalar localtime 1219952008 %>';

my $t = Text::Template::Simple->new( cache => 1 );

my $raw1 = $t->compile( TEMPLATE );

ok( $t->cache->has( data => TEMPLATE          ), "Run 1: Cache has DATA" );
ok( $t->cache->has( id   => $t->cache->id     ), "Run 1: Cache has ID"   );

my $raw2 = $t->compile( TEMPLATE );

ok( $t->cache->has( data => TEMPLATE          ), "Run 2: Cache has DATA" );
ok( $t->cache->has( id   => $t->cache->id     ), "Run 2: Cache has ID"   );

my $raw3 = $t->compile( TEMPLATE, undef, { id => "11_cache_mem_t" } );

ok( $t->cache->has( data => TEMPLATE          ), "Run 3: Cache has DATA" );
ok( $t->cache->has( id   => "11_cache_mem_t" ), "Run 3: Cache has ID"   );
ok( $t->cache->id eq "11_cache_mem_t", "Cache ID OK");

ok( $raw1 eq $raw2, "RAW1 EQ RAW2" );
ok( $raw2 eq $raw3, "RAW2 EQ RAW3" );

ok( $t->cache->type eq 'MEMORY', "Correct cache type is set" );
