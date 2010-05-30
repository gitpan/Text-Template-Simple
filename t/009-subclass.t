#!/usr/bin/env perl -w
# Simple Subclassing
package MyTTS;
use strict;
use warnings;
use base qw(Text::Template::Simple);
use Text::Template::Simple::Constants qw(:fields); # get the object fields 

sub new {
   my $class = shift;
   my $self  = $class->SUPER::new( @_ );
   my $ok    = print "Sub class defined the constructor!\n";
   return $self;
}

sub compile {
   my $self = shift;
   my $ok   = print 'Delimiters are: ' . join( ' & ', @{$self->[DELIMITERS] }) . "\n";
   return $self->SUPER::compile( @_ );
}

package main;

use strict;
use Test::More qw( no_plan );

my $t = MyTTS->new;

ok( $t->compile(q/Just a test/), 'Compiled by subclass');
