#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 2 }

use Text::Template::Simple; 

ok(simple());
ok(simple2());

sub simple {
   my $template = Text::Template::Simple->new(
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
   );
   my $result = $template->compile('t/test.tmpl', ['Burak']);
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

exit;

__END__
