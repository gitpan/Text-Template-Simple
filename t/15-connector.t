#!/usr/bin/env perl -w
package TTS;
use strict;
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

my $t   = Text::Template::Simple->new;
my $sub = TTS->new( cache => 1 );

ok(   $t->connector('Cache')     eq 'Text::Template::Simple::Cache',     'Connector Cache'         );
ok(   $t->connector('Cache::ID') eq 'Text::Template::Simple::Cache::ID', 'Connector Cache::ID'     );
ok(   $t->connector('IO')        eq 'Text::Template::Simple::IO',        'Connector IO'            );
ok(   $t->connector('Tokenizer') eq 'Text::Template::Simple::Tokenizer', 'Connector Tokenizer'     );

ok( $sub->connector('Cache')     eq 'TTS::Cache',                        'Sub-Connector Cache'     );
ok( $sub->connector('Cache::ID') eq 'TTS::Cache::ID',                    'Sub-Connector Cache::ID' );
ok( $sub->connector('IO')        eq 'TTS::IO',                           'Sub-Connector IO'        );
ok( $sub->connector('Tokenizer') eq 'TTS::Tokenizer',                    'Sub-Connector Tokenizer' );

ok(
   $sub->compile(q|<%my@p=@_%>Testing compile from subclass: <%=$p[0]%>|,['Test'])
   eq
   'Testing compile from subclass: Test',
   'Testing compile from subclass'
);
