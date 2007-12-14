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

use constant SUBSTR_LENGTH =>  1;

use Carp qw( croak );

$VERSION = '0.10';

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
   $self->[ID_DS] = shift || croak "tokenize(): Start delimiter is missing";
   $self->[ID_DE] = shift || croak "tokenize(): End delimiter is missing";
   $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my $self       = shift;
   my $tmp        = shift || croak "tokenize(): Template string is missing";
   my $map_keys   = shift;
   my($ds, $de)   = @{ $self };
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
         push @tokens, $self->token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   return \@tokens;
}

sub token_code {
   my $self     = shift;
   my $str      = shift;
   my $inside   = shift;
   my $map_keys = shift;
   my $tree     = shift;
   my $first    = substr $str, 0, SUBSTR_LENGTH;
   #my $last     = substr $str, length($str) - 1, SUBSTR_LENGTH;

   my($cmd, $len, $cb, $buf);
   TCODE: foreach $cmd ( @COMMANDS ) {
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

   return [ $map_keys ? 'MAPKEY' : 'CODE', $str                 ] if $inside;
   return [                         'RAW', $self->tilde( $str ) ];
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
