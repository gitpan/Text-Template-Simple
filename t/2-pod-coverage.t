#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

eval "use Test::Pod::Coverage;1";
if($@) {
   plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
} else {
   plan tests => 1;
   # by-pass Text::Template methods
   pod_coverage_ok('Text::Template', { trustme => [qw/
      TTerror
      Version
      always_prepend
      prepend_text
      set_source_data
      source
   /]});
}
