#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw( :chomp );

my $t     = Text::Template::Simple->new;
my $pre   = Text::Template::Simple->new( pre_chomp  => CHOMP_ALL    );
my $post  = Text::Template::Simple->new( post_chomp => CHOMP_ALL    );
my $prec  = Text::Template::Simple->new( pre_chomp  => COLLAPSE_ALL );
my $postc = Text::Template::Simple->new( post_chomp => COLLAPSE_ALL );
my $both  = Text::Template::Simple->new( pre_chomp  => CHOMP_ALL,
                                         post_chomp => CHOMP_ALL    );
my $bothc = Text::Template::Simple->new( pre_chomp  => COLLAPSE_ALL,
                                         post_chomp => COLLAPSE_ALL );

my $test = <<'THIS';
BU
<%=~ 'R' ~%>
AK
<%- my $z -%>
FF
THIS

my $expect = "BU R AKFF\n";
my $got    = $t->compile( $test );

ok( $got eq $expect, "'$got' eq '$expect'" );

ok( $t->compile(     q{| <%-  %> |})     eq q{| |}   , 'Chomping 1' );
ok( $t->compile(     q{| <%- -%> |})     eq q{||}    , 'Chomping 2' );
ok( $t->compile(    qq{|\n <%~  %> |})   eq q{|  |}  , 'Chomping 3' );
ok( $t->compile(    qq{|\n <%~ ~%> \n|}) eq q{|  |}  , 'Chomping 4' );
ok( $t->compile(    qq{|\n <%~  -%> |})  eq q{| |}   , 'Chomping 5' );
ok( $t->compile(    qq{|\n <%- ~%> \n|}) eq q{| |}   , 'Chomping 6' );

ok( $pre->compile(   q{| <%  %> |})      eq q{| |}   , 'Chomping 7' );
ok( $post->compile(  q{| <%  %> |})      eq q{| |}   , 'Chomping 8' );
ok( $prec->compile(  q{|  <%  %>  |})    eq q{|   |} , 'Chomping 9' );
ok( $postc->compile( q{|  <%  %>  |})    eq q{|   |} , 'Chomping 10' );
ok( $both->compile(  q{| <%  %> |})      eq q{||}    , 'Chomping 11' );
ok( $bothc->compile( q{|  <%  %>  |})    eq q{|  |}  , 'Chomping 12' );

# TODO: this test currently does not cover the full chomping interface
