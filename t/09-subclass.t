#!/usr/bin/env perl -w
# Simple Subclassing

package MyTTS;
use strict;
use base qw(Text::Template::Simple);
use Text::Template::Simple::Constants qw(:fields); # get the object fields 

sub new {
   my $class = shift;
   my $self  = $class->SUPER::new( @_ );
   print "Sub class defined the constructor!\n";
   $self;
}

sub compile {
   my $self = shift;
   print "Delimiters are: " . join( ' & ', @{$self->[DELIMITERS] }) . "\n";
   return $self->SUPER::compile( @_ );
}

package main;

use strict;
use Test::More qw( no_plan );

my $t = MyTTS->new;
#$t->DEBUG(0);

ok( $t->compile(q/Just a test/), "Define output buffer variables");

exit;

__END__
