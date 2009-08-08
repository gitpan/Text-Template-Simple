#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple; 

ok(simple() , "Simple test 1");
ok(simple2(), "Simple test 2");

my $t = Text::Template::Simple->new();

ok( $t->cache->type eq 'OFF', "Correct cache type is set" );

sub simple {
   my $template = Text::Template::Simple->new(
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
   );
   my $result = $template->compile('t/data/test.tts', ['Burak']);
   #warn "[COMPILED] $result\n";
   return $result;
}

sub simple2 {
   my $template = Text::Template::Simple->new;
   my $result   = $template->compile(
                  'Hello <%name%>. Foo is: <%foo%> and bar is <%bar%>.',
                  [
                     name => 'Burak',
                     foo  => 'bar',
                     bar  => 'baz',
                  ],
                  {
                     map_keys => 1
                  });
   #warn "[COMPILED] $result\n";
   return $result;
}
