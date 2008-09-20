package Text::Template::Simple::Tokenizer;
use strict;
use vars qw($VERSION);
use constant CMD_CHAR             =>  0;
use constant CMD_ID               =>  1;
use constant CMD_CB               =>  2; # callback

use constant TOKEN_ID             =>  0;
use constant TOKEN_STR            =>  1;
use constant TOKEN_EXTRA          =>  2;
use constant TOKEN_COLLAPSE       =>  3;

use constant LAST_TOKEN           => -1;
use constant PREVIOUS_TOKEN       => -3;

use constant ID_DS                =>  0;
use constant ID_DE                =>  1;
use constant ID_PRE_CHOMP         =>  2;
use constant ID_POST_CHOMP        =>  3;

use constant SUBSTR_OFFSET_FIRST  =>  0;
use constant SUBSTR_OFFSET_SECOND =>  1;
use constant SUBSTR_LENGTH        =>  1;

use Carp qw( croak );
use Text::Template::Simple::Util      qw();
use Text::Template::Simple::Constants qw( :chomp :token :directive );

$VERSION = '0.54_02';

my @COMMANDS = (
   # cmd                      id        callback
   [ DIRECTIVE_CAPTURE  , qw/ CAPTURE         / ],
   [ DIRECTIVE_DYNAMIC  , qw/ DYNAMIC   trim  / ],
   [ DIRECTIVE_STATIC   , qw/ STATIC    trim  / ],
   [ DIRECTIVE_NOTADELIM, qw/ NOTADELIM       / ],
   [ DIRECTIVE_COMMENT  , qw/ COMMENT         / ],
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
   my(@tokens, $inside, $extra, $ecollapse);

   OUT_TOKEN: foreach my $i ( split /($qds)/, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ DELIMSTART => $i ];
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
               # these will be reset in _chomp()
               $extra     = $last->[TOKEN_EXTRA];
               $ecollapse = $last->[TOKEN_COLLAPSE];
               push @tokens, [ DELIMEND => $j ];
            }
            $inside = 0;
            next IN_TOKEN;
         }

         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
         $self->_chomp( \@tokens, \$extra, \$ecollapse );
      }
   }

   if ( $self->can('DEBUG_TOKENS') ) {
      require Data::Dumper;
      my $struct = Data::Dumper->new( [ \@tokens ], [ '*TOKENS' ] );
      Text::Template::Simple::Util::LOG( DEBUG => $struct->Dump );
   }

   return \@tokens;
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

   TCODE: {
      my($copen, $cclose, $ctoken, $cc) = $self->_chomp_token( $second, $last );

      foreach my $cmd ( @COMMANDS, $self->_user_commands ) {

         if ( $first eq $cmd->[CMD_CHAR] ) {
            my $cb   = $map_keys ? 'quote' : $cmd->[CMD_CB];
            my $soff = $copen ? 2 : 1;
            my $slen = $len - ($cclose ? $soff+1 : 1);
            my $buf  = substr $str, $soff, $slen;

            if ( $cmd->[CMD_ID] eq 'NOTADELIM' && $inside ) {
               $buf = $self->[ID_DS] . $buf;
               $tree->[LAST_TOKEN][TOKEN_ID] = 'DISCARD';
            }

            return [
                     $map_keys ? 'RAW'              : $cmd->[CMD_ID],
                     $cb       ? $self->$cb( $buf ) : $buf,
                     ($ctoken  ? ($ctoken, $cc )    : () ),
                   ];
         }
      }
   }

   if ( $inside ) {
      my($copen, $cclose, $ctoken, $cc) = $self->_chomp_token( $first, $last );
      my $soff = $copen ? 1 : 0;
      my $slen = $len - ( $cclose ? $soff+1 : 0 );

      return   [
                  $map_keys ? 'MAPKEY' : 'CODE',
                  substr($str, $soff, $slen),
                  ($ctoken ? ($ctoken, $cc) : () ),
               ];
   }

   return [ RAW => $self->tilde( $str ) ];
}

sub _chomp {
   # optimize away the unnecessary white space before parsing happens
   my $self      = shift;
   my $tree_ref  = shift;
   my $extra_ref = shift;
   my $xc_ref    = shift;
   my $is_close  = defined($$extra_ref) && (
                        $$extra_ref & TOKEN_CHOMP_CLOSE ||
                        $$extra_ref & TOKEN_CHOMP_BOTH
                  );

   my $last = $tree_ref->[LAST_TOKEN];

   if ( $is_close ) {
      my $collapse       = $last->[TOKEN_COLLAPSE] || $$xc_ref || CHOMP_NONE;
      my $cc             = $collapse & CHOMP_COLLAPSE_POST ? ' ' : undef;
      $last->[TOKEN_STR] = $self->ltrim( $last->[TOKEN_STR], $cc );
      my $short_circuit  = $$extra_ref & TOKEN_CHOMP_CLOSE; # by-pass the code below?
      $$extra_ref        = undef; # reset!
      $$xc_ref           = undef; # reset
      return if $short_circuit;
   }

   my $type = $last->[TOKEN_EXTRA] || return;

   if ( $type & TOKEN_CHOMP_OPEN || $type & TOKEN_CHOMP_BOTH ) {
      if ( @{ $tree_ref } >= 2 ) {
         my $t  = $tree_ref->[PREVIOUS_TOKEN];
         my $cc = $last->[TOKEN_COLLAPSE] & CHOMP_COLLAPSE_PRE ? ' ' : undef;
         $t->[TOKEN_STR] = $self->rtrim( $t->[TOKEN_STR], $cc );
      }
   }

   return;
}

sub _chomp_token {
   my($self, $open, $close) = @_;
   my($pre, $post) = ( $self->[ID_PRE_CHOMP], $self->[ID_POST_CHOMP] );
   my $c      = CHOMP_NONE;

   my $copen  = $open eq DIRECTIVE_CHOMP_NONE     ? -1
              : $open eq DIRECTIVE_CHOMP_COLLAPSE ? do{$c |= CHOMP_COLLAPSE_PRE; 1}
              : $pre  &  CHOMP_COLLAPSE           ? do{$c |= CHOMP_COLLAPSE_PRE; 1}
              : $pre  &  CHOMP_ALL                ? 1
              : $open eq DIRECTIVE_CHOMP          ? 1
              :                                     0
              ;

   my $cclose = $close eq DIRECTIVE_CHOMP_NONE     ? -1
              : $close eq DIRECTIVE_CHOMP_COLLAPSE ? do{$c |= CHOMP_COLLAPSE_POST;1}
              : $post  &  CHOMP_COLLAPSE           ? do{$c |= CHOMP_COLLAPSE_POST;1}
              : $post  &  CHOMP_ALL                ? 1
              : $close eq DIRECTIVE_CHOMP          ? 1
              :                                      0
              ;

   my $cboth  = $copen > 0 && $cclose > 0;

   my $token = $cboth      ? TOKEN_CHOMP_BOTH
             : $copen  > 0 ? TOKEN_CHOMP_OPEN
             : $cclose > 0 ? TOKEN_CHOMP_CLOSE
             :               TOKEN_CHOMP_NONE
             ;

   return $copen, $cclose, $token, $c;
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub tilde { shift; Text::Template::Simple::Util::escape( '~' => @_ ) }
sub quote { shift; Text::Template::Simple::Util::escape( '"' => @_ ) }
sub trim  { shift; Text::Template::Simple::Util::trim(          @_ ) }
sub rtrim { shift; Text::Template::Simple::Util::rtrim(         @_ ) }
sub ltrim { shift; Text::Template::Simple::Util::ltrim(         @_ ) }

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
