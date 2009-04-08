#!/usr/bin/env perl -w
use strict;
use Test::More;

# build tool runs the whole test suite on the monolithic version.
# Don't bother testing it
plan skip_all => "Skipping for monolith build test" if $ENV{TTS_TESTING_MONOLITH_BUILD};

eval "use Test::Pod::Coverage;1";
if ( $@ ) {
   plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
} else {
   all_pod_coverage_ok();
}
