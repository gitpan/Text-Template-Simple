#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 1 }

use Text::Template::Simple; 

ok(simple());

sub simple {
   my $template = Text::Template::Simple->new(
      delimiters => ['{', '}'],
      globals => {
         foo  => 'bar'  , # define $foo
         bar  => ['baz'], # define @bar
         blah => {        # define %blah
            key => 'value',
         },
      },
      dummy => "MY::Dummy::Class::To::Fill::In::Templates",
      # reset_dummy => 1, # reset dummy class' symbol table explicitly
    );

   my $result = $template->compile(
                  'Hello {$foo}. Key is: {$blah{key}} and Your name is {$name}.',
                  {
                     name => 'Burak',
                  });
   return $result;
}

exit;

__END__
