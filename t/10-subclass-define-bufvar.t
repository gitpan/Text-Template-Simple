#!/usr/bin/env perl -w
# Subclassing to define the buffer variables
use strict;
use Test::More qw( no_plan );

my $t = MyTTS->new;
$t->DEBUG(0);

ok( $t->compile(q/Just a test/), "Define output buffer variables");

exit;

package MyTTS;
use base qw(Text::Template::Simple);
Text::Template::Simple->DEBUG(0);

# if you relied on the old interface or relied on the buffer var being $OUT,
# then you have to subclass the module to restore that behaviour.
# (not a good idea though)
sub _output_buffer_var {
   my $self    = shift;
   my $is_hash = shift;
   return $is_hash ? '$OUT_HASH' : '$OUT';
}

__END__
