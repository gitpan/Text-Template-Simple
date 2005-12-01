#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 1 }

use Text::Template::Simple; 

ok(simple());

sub simple {
   use Text::Template::Simple;

   my $template = Text::Template::Simple->new(
      globals => {
         foo  => 'bar'  , # define $foo
         bar  => ['baz'], # define @bar
         blah => {        # define %blah
            key => 'value',
         },
      },
   );

   my $result = $template->compile(
                  'Hello <%$foo%>. Key is: <%$blah{key}%> and Your name is <%$name%>.',
                  {
                     name => 'Burak',
                  });
   return $result;
}

exit;

__END__
