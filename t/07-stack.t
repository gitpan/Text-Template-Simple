#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

local $SIG{__WARN__} = sub { # silence stack dumps
   return if $_[0] =~ m{DUMPING CALLER STACK FOR}s;
   return if $_[0] =~ m{Caller stack type}s;
   warn $_[0];
};

ok(simple('string'), "String Dumper");
ok(simple('html_comment'),"HTML Comment Dumper");
ok(simple('html_table'), "HTML Table Dumper");

eval { require Text::Table; };

if ( ! $@ ) {
   ok(simple('text_table'), "Text Table Dumper");
}

sub simple {
   my $type = shift || die "type?";
   my $template = Text::Template::Simple->new(
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
      stack    => $type,
   );
   my $result = $template->compile('t/test.tmpl', ['Burak']);
   #warn "[COMPILED] $result\n";
   return $result;
}

exit;

__END__
