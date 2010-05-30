#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use File::Temp qw( tempdir );
use constant PERL_55     =>              $] < 5.006;
use constant PERL_56     => ! PERL_55 && $] < 5.007;
use constant PERL_LEGACY => PERL_55 || PERL_56;
use constant IS_TAINT    => __PACKAGE__->can('TAINTMODE');
use constant TEMPLATE    => q(Time now: <%=scalar localtime 1219952008 %>);

use Text::Template::Simple;

# ref: http://rt.cpan.org/Public/Bug/Display.html?id=45885
for my $path ( qw( TEMP TMP ) ) {
    last if ! IS_TAINT || ! PERL_LEGACY;
    next if ! $ENV{ $path }; # this is just a test you know :p
    $ENV{ $path } = $1 if $ENV{ $path } =~ m{\A (.*) \z}xms;
}

SKIP: {

    #if ( PERL_LEGACY && IS_TAINT && $^O eq 'freebsd' ) {
    #    skip "This version of perl in this platform seems to have a bug in "
    #        ."it that causes failures under taint mode. See this bug report "
    #        ."for the details on this issue: "
    #        ."http://rt.cpan.org/Public/Bug/Display.html?id=45885";
    #}

    my $TEMPDIR = tempdir( CLEANUP => PERL_LEGACY ? 0 : 1 );

    my $t = Text::Template::Simple->new(
                cache     => 1,
                cache_dir => $TEMPDIR,
            );

    my $raw1 = $t->compile( TEMPLATE );

    ok( $t->cache->has( data => TEMPLATE        ), 'Run 1: Cache has DATA' );
    ok( $t->cache->has( id   => $t->cache->id   ), 'Run 1: Cache has ID'   );

    my $raw2 = $t->compile( TEMPLATE );

    ok( $t->cache->has( data => TEMPLATE        ), 'Run 2: Cache has DATA' );
    ok( $t->cache->has( id   => $t->cache->id   ), 'Run 2: Cache has ID'   );

    my $raw3 = $t->compile( TEMPLATE, 0, { id => '12_cache_disk_t', chkmt => 1 } );

    ok( $t->cache->has( data => TEMPLATE          ), 'Run 3: Cache has DATA' );
    ok( $t->cache->has( id   => '12_cache_disk_t' ), 'Run 3: Cache has ID'   );
    ok( $t->cache->id eq '12_cache_disk_t'         , 'Cache ID OK'           );

    ok( $raw1 eq $raw2, "RAW1 EQ RAW2 - '$raw1' eq '$raw2'" );
    ok( $raw2 eq $raw3, "RAW2 EQ RAW3 - '$raw2' eq '$raw3'" );

    ok( $t->cache->type eq 'DISK', 'Correct cache type is set' );
}
