#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
package TTS;
use strict;
use warnings;
use base qw(Text::Template::Simple);

my %CONNECTOR = ( # Default classes list
   'Cache'     => 'TTS::Cache',
   'Cache::ID' => 'TTS::Cache::ID',
   'IO'        => 'TTS::IO',
   'Tokenizer' => 'TTS::Tokenizer',
);

sub connector {
    my $self = shift;
    my $id   = shift;
    return $CONNECTOR{ $id };
}

package TTS::Cache;
use base qw(Text::Template::Simple::Cache);

package TTS::Cache::ID;
use base qw(Text::Template::Simple::Cache::ID);

package TTS::IO;
use base qw(Text::Template::Simple::IO);

package TTS::Tokenizer;
use base qw(Text::Template::Simple::Tokenizer);

package main;
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $t = Text::Template::Simple->new;
my $s = TTS->new( cache => 1 );

my $p = 'Text::Template::Simple::';

ok( $t->connector('Cache')     eq $p . 'Cache',     'Connector Cache'       );
ok( $t->connector('Cache::ID') eq $p . 'Cache::ID', 'Connector Cache::ID'   );
ok( $t->connector('IO')        eq $p . 'IO',        'Connector IO'          );
ok( $t->connector('Tokenizer') eq $p . 'Tokenizer', 'Connector Tokenizer'   );

ok( $s->connector('Cache')     eq 'TTS::Cache',     'S-Connector Cache'     );
ok( $s->connector('Cache::ID') eq 'TTS::Cache::ID', 'S-Connector Cache::ID' );
ok( $s->connector('IO')        eq 'TTS::IO',        'S-Connector IO'        );
ok( $s->connector('Tokenizer') eq 'TTS::Tokenizer', 'S-Connector Tokenizer' );

my $template = q|<%my@p=@_%>Compile from subclass: <%=$p[0]%>|;

ok(
    $s->compile( $template, [ 'Test' ] ) eq 'Compile from subclass: Test',
    'Compile from subclass'
);
