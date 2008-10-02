#!/usr/bin/env perl -w
use strict;
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

ok( $t->compile(    "| <%-  %> |")     eq "| |"   );
ok( $t->compile(    "| <%- -%> |")     eq "||"    );
ok( $t->compile(    "|\n <%~  %> |")   eq "|  |"  );
ok( $t->compile(    "|\n <%~ ~%> \n|") eq "|  |"  );
ok( $t->compile(    "|\n <%~  -%> |")  eq "| |"   );
ok( $t->compile(    "|\n <%- ~%> \n|") eq "| |"   );

ok( $pre->compile(  "| <%  %> |")      eq "| |"   );
ok( $post->compile( "| <%  %> |")      eq "| |"   );
ok( $prec->compile( "|  <%  %>  |")    eq "|   |" );
ok( $postc->compile("|  <%  %>  |")    eq "|   |" );
ok( $both->compile( "| <%  %> |")      eq "||"    );
ok( $bothc->compile("|  <%  %>  |")    eq "|  |"  );

# TODO: this test currently does not cover all chomping interface
