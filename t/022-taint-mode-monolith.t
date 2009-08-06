#!perl -Tw
#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new(
   monolith => 1,
);

my $got = $t->compile( 't/data/monolith.tts' );
chomp $got;

is( $got, expected(), "Testing Monolith");

sub expected {
    <<'EXPECT';

[ dynamic include error ] Interpolated includes don't work under monolith option. Please disable monolith and use the 'SHARE' directive in the include command: t/data/monolith-1.tts | PARAM: 'test'
$VAR1 = [
          42,
          {
            'abc' => 123
          },
          1,
          2,
          3
        ];

$VAR1 = [
          42,
          {
            'abc' => 123
          },
          1,
          2,
          3
        ];

EXPECT
}
