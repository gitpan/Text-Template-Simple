package Text::Template::Simple::Tokenizer;
use strict;
use vars qw($VERSION);
use constant CMD_CHAR      =>  0;
use constant CMD_ID        =>  1;
use constant CMD_CB        =>  2; # callback

use constant TOKEN_ID      =>  0;
use constant TOKEN_STR     =>  1;
use constant LAST_TOKEN    => -1;

use constant ID_DS         =>  0;
use constant ID_DE         =>  1;
use constant ID_FU         =>  2;

use constant SUBSTR_OFFSET =>  0;
use constant SUBSTR_LENGTH =>  1;

use Carp qw( croak );

$VERSION = '0.50';

my @COMMANDS = (
   #   cmd id        callback
   [ qw/ = CAPTURE        / ],
   [ qw/ * DYNAMIC   trim / ],
   [ qw/ + STATIC    trim / ],
   [ qw/ ! NOTADELIM      / ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS] = shift || croak "Start delimiter is missing";
   $self->[ID_DE] = shift || croak "End delimiter is missing";
   $self->[ID_FU] = shift || 0;
   $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my $self       = shift;
   my $tmp        = shift || croak "tokenize(): Template string is missing";
   my $map_keys   = shift;
   my($ds, $de)   = ($self->[ID_DS], $self->[ID_DE]);
   my($qds, $qde) = map { quotemeta $_ } $ds, $de;

   my(@tokens, $inside, $last, $i, $j);

   OUT_TOKEN: foreach $i ( split /($qds)/, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ DELIMSTART => $i ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach $j ( split /($qde)/, $i ) {
         if ( $j eq $de ) {
            $last = $tokens[LAST_TOKEN];
            if ( $last->[TOKEN_ID] eq 'NOTADELIM' ) {
               $last->[TOKEN_STR] = $self->tilde( $last->[TOKEN_STR] . $de );
            }
            else {
               push @tokens, [ DELIMEND => $j ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   return \@tokens;
}

sub _token_code {
   my $self     = shift;
   my $str      = shift;
   my $inside   = shift;
   my $map_keys = shift;
   my $tree     = shift;
   my $first    = substr $str, SUBSTR_OFFSET, SUBSTR_LENGTH;
   # $first is the left-cmd, perhaps we can use a right-cmd?
   #my $last    = substr $str, length($str) - 1, SUBSTR_LENGTH;
   my $fu       = $self->[ID_FU];

   my($cmd, $len, $cb, $buf);
   TCODE: foreach $cmd ( @COMMANDS, $self->_user_commands ) {
      if ( $first eq $cmd->[CMD_CHAR] ) {
         $len = length($str);
         $cb  = $cmd->[CMD_CB];
         $buf = substr $str, 1, $len - 1;
         if ( $cmd->[CMD_ID] eq 'NOTADELIM' && $inside ) {
            $buf = $self->[ID_DS] . $buf;
            $tree->[LAST_TOKEN][TOKEN_ID] = 'DISCARD';
         }
         $cb = 'quote' if $map_keys;
         return [
                  $map_keys ? 'RAW'              : $cmd->[CMD_ID],
                  $cb       ? $self->$cb( $buf ) : $buf
                ];
      }
   }

   if ( $inside ) {
      return [ MAPKEY => $str ] if $map_keys;
      #$str = $self->trim( $str );
      return [ CODE   => $str ];
   }
   return [ RAW => $self->tilde( $str ) ];
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub tilde {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ \~ }{\\~}xmsg;
      $s;
}

sub quote {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ " }{\\"}xmsg;
      $s;
}

sub trim {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ \A \s+    }{}xms;
      $s    =~ s{    \s+ \z }{}xms;
      $s;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Tokenizer - Tokenizer for Text::Template::Simple

=head1 SYNOPSIS

   use strict;
   use constant TYPE => 0;
   use constant DATA => 1;
   use Text::Template::Simple::Tokenize;
   my $t = Text::Template::Simple::Tokenize->new( $start_delim, $end_delim );
   my $tokens = $t->tokenize( $raw_data );
   foreach my $token ( @{ $tokens } ) {
      printf "Token type: %s\n", $token->[TYPE];
      printf "Token data: %s\n", $token->[DATA];
   }

=head1 DESCRIPTION

Tokenizes the input with the defined delimiter pair.

=head1 METHODS

=head2 new

The object constructor. Accepts two parameters in this order:
C<start_delimiter> and C<end_delimiter>.

=head2 tokenize

Tokenizes the input with the supplied delimiter pair. Accepts a single
parameter: the raw template string.

=head2 ESCAPE METHODS

=head2 tilde

Escapes the tilde character.

=head3 quote

Escapes double quotes.

=head3 trim

Trims the input string.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
