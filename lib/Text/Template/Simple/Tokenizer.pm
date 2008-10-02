package Text::Template::Simple::Tokenizer;
use strict;
use vars qw($VERSION);

$VERSION = '0.54_14';

use constant CMD_CHAR             =>  0;
use constant CMD_ID               =>  1;
use constant CMD_CB               =>  2; # callback

use constant ID_DS                =>  0;
use constant ID_DE                =>  1;
use constant ID_PRE_CHOMP         =>  2;
use constant ID_POST_CHOMP        =>  3;

use constant SUBSTR_OFFSET_FIRST  =>  0;
use constant SUBSTR_OFFSET_SECOND =>  1;
use constant SUBSTR_LENGTH        =>  1;

use Carp qw( croak );
use Text::Template::Simple::Util      qw( LOG );
use Text::Template::Simple::Constants qw( :chomp :directive :token );

my @COMMANDS = (
   # cmd                      id        callback
   [ DIR_CAPTURE  , qw/ CAPTURE         / ],
   [ DIR_DYNAMIC  , qw/ DYNAMIC   trim  / ],
   [ DIR_STATIC   , qw/ STATIC    trim  / ],
   [ DIR_NOTADELIM, qw/ NOTADELIM       / ],
   [ DIR_COMMENT  , qw/ COMMENT         / ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS]         = shift || croak "Start delimiter is missing";
   $self->[ID_DE]         = shift || croak "End delimiter is missing";
   $self->[ID_PRE_CHOMP]  = shift || CHOMP_NONE;
   $self->[ID_POST_CHOMP] = shift || CHOMP_NONE;
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

   OUT_TOKEN: foreach my $i ( split /($qds)/, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ $i, 'DELIMSTART', [], undef ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach my $j ( split /($qde)/, $i ) {
         if ( $j eq $de ) {
            my $last = $tokens[LAST_TOKEN];
            if ( $last->[TOKEN_ID] eq 'NOTADELIM' ) {
               $last->[TOKEN_STR] = $self->tilde( $last->[TOKEN_STR] . $de );
            }
            else {
               push @tokens, [ $j, 'DELIMEND', [], undef ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   $self->_debug_tokens( \@tokens ) if $self->can('DEBUG_TOKENS');

   return \@tokens;
}

sub tilde { shift; Text::Template::Simple::Util::escape( '~' => @_ ) }
sub quote { shift; Text::Template::Simple::Util::escape( '"' => @_ ) }
sub trim  { shift; Text::Template::Simple::Util::trim(          @_ ) }

sub _debug_tokens {
   my $self   = shift;
   my $tokens = shift;
   # TODO: heredocs look ugly
   my $buf = <<'HEAD';

---------------------------
       TOKEN DUMP
---------------------------
HEAD

   my $tmp = <<'DUMP';
ID        : %s
STRING    : %s
CHOMP_NEXT: %s
CHOMP_PREV: %s
TRIGGER   : %s
---------------------------
DUMP

   foreach my $t ( @{ $tokens } ) {
      my $s = $t->[TOKEN_STR];
      $s =~ s{\r}{\\r}xmsg;
      $s =~ s{\n}{\\n}xmsg;
      $s =~ s{\f}{\\f}xmsg;
      $s =~ s{\s}{\\s}xmsg;
      my @v = (
         scalar $self->_visualize_chomp( $t->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT] ),
         scalar $self->_visualize_chomp( $t->[TOKEN_CHOMP][TOKEN_CHOMP_PREV] ),
         scalar $self->_visualize_chomp( $t->[TOKEN_TRIGGER]                 )
      );
      $buf .= sprintf $tmp, $t->[TOKEN_ID], $s, @v;
   }
   Text::Template::Simple::Util::LOG( DEBUG => $buf );
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub _token_code {
   my $self     = shift;
   my $str      = shift;
   my $inside   = shift;
   my $map_keys = shift;
   my $tree     = shift;
   # $first is the left-cmd, $last is the right-cmd. $second is the extra
   my $first    = substr $str, SUBSTR_OFFSET_FIRST , SUBSTR_LENGTH;
   my $second   = substr $str, SUBSTR_OFFSET_SECOND, SUBSTR_LENGTH;
   my $last     = substr $str, length($str) - 1    , SUBSTR_LENGTH;
   my $len      = length($str);

   HANDLE_OUTSIDE: {
      foreach my $cmd ( @COMMANDS, $self->_user_commands ) {
         if ( $first eq $cmd->[CMD_CHAR] ) {
            my($copen, $cclose, $ctoken) = $self->_chomp_token( $second, $last );
            my $cb   = $map_keys ? 'quote' : $cmd->[CMD_CB];
            my $soff = $copen ? 2 : 1;
            my $slen = $len - ($cclose ? $soff+1 : 1);
            my $buf  = substr $str, $soff, $slen;

            if ( $cmd->[CMD_ID] eq 'NOTADELIM' && $inside ) {
               $buf = $self->[ID_DS] . $buf;
               $tree->[LAST_TOKEN][TOKEN_ID] = 'DISCARD';
            }

            my $needs_chomp = defined($ctoken);
            $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

            my $id  = $map_keys ? 'RAW'              : $cmd->[CMD_ID];
            my $val = $cb       ? $self->$cb( $buf ) : $buf;

            return [
                     $val,
                     $id,
                     [CHOMP_NONE, CHOMP_NONE],
                     $needs_chomp ? $ctoken : undef # trigger
                   ];
         }
      }
   }

   if ( $inside ) {
      my($copen, $cclose, $ctoken) = $self->_chomp_token( $first, $last );
      my $soff = $copen ? 1 : 0;
      my $slen = $len - ( $cclose ? $soff+1 : 0 );

      my $needs_chomp = defined($ctoken);
      $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

      return   [
                  substr($str, $soff, $slen),
                  $map_keys ? 'MAPKEY' : 'CODE',
                  [ CHOMP_NONE, CHOMP_NONE ],
                  $needs_chomp ? $ctoken : undef # trigger
               ];
   }

   my $trig = $tree->[PREVIOUS_TOKEN] ? $tree->[PREVIOUS_TOKEN][TOKEN_TRIGGER]
            :                           undef
            ;
   return [
            $self->tilde( $str ),
            'RAW',
            [ $trig, CHOMP_NONE ],
            undef
         ];
}


sub _chomp_token {
   my($self, $open, $close) = @_;
   my($pre, $post) = ( $self->[ID_PRE_CHOMP], $self->[ID_POST_CHOMP] );
   my $c      = CHOMP_NONE;

   my $copen  = $open  eq DIR_CHOMP_NONE ? -1
              : $open  eq DIR_COLLAPSE   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre   &  COLLAPSE_ALL   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre   &  CHOMP_ALL      ? do { $c |=     CHOMP_LEFT; 1 }
              : $open  eq DIR_CHOMP      ? do { $c |=     CHOMP_LEFT; 1 }
              :                            0
              ;

   my $cclose = $close eq DIR_CHOMP_NONE ? -1
              : $close eq DIR_COLLAPSE   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post  &  COLLAPSE_ALL   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post  &  CHOMP_ALL      ? do { $c |=    CHOMP_RIGHT; 1 }
              : $close eq DIR_CHOMP      ? do { $c |=    CHOMP_RIGHT; 1 }
              :                            0
              ;

   my $cboth  = $copen > 0 && $cclose > 0;

   $c |= COLLAPSE_ALL if( ($c & COLLAPSE_LEFT) && ($c & COLLAPSE_RIGHT) );
   $c |= CHOMP_ALL    if( ($c & CHOMP_LEFT   ) && ($c & CHOMP_RIGHT   ) );

   return $copen, $cclose, $c || CHOMP_NONE;
}

sub _chomp_prev {
   my($self, $tree, $ctoken) = @_;
   my $prev = $tree->[PREVIOUS_TOKEN] || return; # no previous if this is first
   return if $prev->[TOKEN_ID] ne 'RAW'; # only RAWs can be chomped

   my $tc_prev = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_PREV];
   my $tc_next = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT];

   $prev->[TOKEN_CHOMP] = [
                           $tc_next ? $tc_next           : CHOMP_NONE,
                           $tc_prev ? $tc_prev | $ctoken : $ctoken
                           ];
   return;
}

sub _visualize_chomp {
   my $self  = shift;
   my $param = shift;
   if ( ! defined $param ) {
      return wantarray ? ("undef", "undef") : "undef";
   }

   my @types = (
      [ COLLAPSE_ALL   => COLLAPSE_ALL   ],
      [ COLLAPSE_LEFT  => COLLAPSE_LEFT  ],
      [ COLLAPSE_RIGHT => COLLAPSE_RIGHT ],
      [ CHOMP_ALL      => CHOMP_ALL      ],
      [ CHOMP_LEFT     => CHOMP_LEFT     ],
      [ CHOMP_RIGHT    => CHOMP_RIGHT    ],
      [ CHOMP_NONE     => CHOMP_NONE     ],
      [ COLLAPSE_NONE  => COLLAPSE_NONE  ],
   );

   my $which;
   foreach my $type ( @types ) {
       if ( $type->[1] & $param ) {
           $which = $type->[0];
           last;
       }
   }

   $which ||= "undef";
   return $which if ! wantarray;

   # can be smaller?
   my @test = (
      sprintf( "COLLAPSE_ALL  : %s", $param & COLLAPSE_ALL   ? 1 : 0 ),
      sprintf( "COLLAPSE_LEFT : %s", $param & COLLAPSE_LEFT  ? 1 : 0 ),
      sprintf( "COLLAPSE_RIGHT: %s", $param & COLLAPSE_RIGHT ? 1 : 0 ),
      sprintf( "CHOMP_ALL     : %s", $param & CHOMP_ALL      ? 1 : 0 ),
      sprintf( "CHOMP_LEFT    : %s", $param & CHOMP_LEFT     ? 1 : 0 ),
      sprintf( "CHOMP_RIGHT   : %s", $param & CHOMP_RIGHT    ? 1 : 0 ),
      sprintf( "COLLAPSE_NONE : %s", $param & COLLAPSE_NONE  ? 1 : 0 ),
      sprintf( "CHOMP_NONE    : %s", $param & CHOMP_NONE     ? 1 : 0 ),
   );

   return $which, join( "\n", @test );
}

1;

__END__

=head1 NAME

Text::Template::Simple::Tokenizer - Tokenizer

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

=head3 rtrim

=head3 ltrim

See L<Text::Template::Simple::Util>.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
