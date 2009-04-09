package Text::Template::Simple::Base::Parser;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.62_11';

# internal code templates
my %INTERNAL = (
   # we need string eval in this template to catch syntax errors
   sub_include => q~
      <%OBJECT%>->_compile(
         do {
            local $@;
            my $file = eval '<%INCLUDE%>';
            my $rv;
            if ( my $e = $@ ) {
               chomp $e;
               $file ||= '<%INCLUDE%>';
               my $m = "The parameter ($file) is not a file. "
                     . "Error from sub-include ($file): $e";
               $rv = [ ERROR => '<%ERROR_TITLE%> ' . $m ]
            }
            else {
               $rv = $file;
            }
            $rv;
         },
         <%PARAMS%>,
         {
            _sub_inc => '<%TYPE%>',
            _filter  => '<%FILTER%>',
         }
      )
   ~,
   no_monolith => q*
      <%OBJECT%>->compile(
         q~<%FILE%>~,
         undef,
         {
            chkmt    => 1,
            _sub_inc => q~<%TYPE%>~,
         }
      );
   *,

   # see _parse()
   map_keys_check => q(
      <%BUF%> .= exists <%HASH%>->{"<%KEY%>"}
               ? (
                  defined <%HASH%>->{"<%KEY%>"}
                  ? <%HASH%>->{"<%KEY%>"}
                  : "[ERROR] Key not defined: <%KEY%>"
                  )
               : "[ERROR] Invalid key: <%KEY%>"
               ;
   ),

   map_keys_init => q(
      <%BUF%> .= <%HASH%>->{"<%KEY%>"} || '';
   ),
   map_keys_default => q(
      <%BUF%> .= <%HASH%>->{"<%KEY%>"};
   ),
);

sub _internal {
   my $self = shift;
   my $id   = shift            || fatal('tts.base.parser._internal.id');
   my $rv   = $INTERNAL{ $id } || fatal('tts.base.parser._internal.id');
   return $rv;
}

sub _parse {
   my $self     = shift;
   my $raw      = shift;
   my $map_keys = shift; # code sections are hash keys
   my $cache_id = shift;
   my $as_is    = shift; # i.e.: do not parse -> static include
   #$self->[NEEDS_OBJECT] = 0; # reset

   my $resume   = $self->[RESUME] || '';
   my $ds       = $self->[DELIMITERS][DELIM_START];
   my $de       = $self->[DELIMITERS][DELIM_END  ];
   my $faker    = $self->[INSIDE_INCLUDE] ? $self->_output_buffer_var
                                          : $self->[FAKER]
                                          ;
   my $buf_hash = $self->[FAKER_HASH];
   my $toke     = $self->connector('Tokenizer')->new(
                     $ds, $de, $self->[PRE_CHOMP], $self->[POST_CHOMP]
                  );
   my $code     = '';
   my $inside   = 0;

   my($mko, $mkc) = $self->_parse_mapkeys( $map_keys, $faker, $buf_hash );

   LOG( RAW => $raw ) if ( DEBUG() > 3 );

   my $handler = $self->[USER_THANDLER];

   my $w_raw  = sub { ";$faker .= q~$_[0]~;" };
   my $w_cap  = sub { ";$faker .= sub {" . $_[0] . "}->();"; };
   my $w_code = sub { $_[0] . ';' };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $as_is;

   # fetch and walk the tree
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $map_keys ) } ) {
      my($str, $id, $chomp, undef) = @{ $token };
      LOG( TOKEN => $toke->_visualize_tid($id) . " => $str" ) if DEBUG() > 1;
      next PARSER if T_DISCARD == $id;
      next PARSER if T_COMMENT == $id;

      if ( T_DELIMSTART == $id ) { $inside++; next PARSER; }
      if ( T_DELIMEND   == $id ) { $inside--; next PARSER; }

      if ( T_RAW == $id || T_NOTADELIM == $id ) {
         $code .= $w_raw->( $self->_chomp( $str, $chomp ) );
      }

      elsif ( T_CODE == $id ) {
         $code .= $w_code->($resume ? $self->_resume($str, 0, 1) : $str);
      }

      elsif ( T_CAPTURE == $id ) {
         $code .= $faker;
         $code .= $resume ? $self->_resume($str, RESUME_NOSTART)
                :           " .= sub { $str }->();";
      }

      elsif ( T_DYNAMIC == $id || T_STATIC == $id ) {
         $self->[NEEDS_OBJECT]++;
         $code .= $w_cap->( $self->_include($id, $str) );
      }

      elsif ( T_MAPKEY == $id ) {
         $code .= sprintf $mko, $mkc ? ( ($str) x 5 ) : $str;
      }

      elsif ( T_COMMAND == $id ) {
         my($head, $raw_block) = split /;/, $str, 2;
         my @buf = split RE_PIPE_SPLIT, '|' . trim($head);
         shift(@buf);
         my %com = map { trim $_ } @buf;

         if ( $com{FILTER} ) {
            # embed into the template & NEEDS_OBJECT++ ???
            local $self->[FILENAME] = '<ANON BLOCK>';
            $self->_call_filters(
               \$raw_block,
               split RE_FILTER_SPLIT, $com{FILTER}
            );
         }

         $code .= $w_raw->($raw_block);
      }

      else {
         if ( $handler ) {
            LOG( USER_THANDLER => "$id") if DEBUG();
            $code .= $handler->(
                        $self, $id ,$str, { capture => $w_cap, raw => $w_raw }
                     );
         }
         else {
            LOG( UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)")
               if DEBUG();
            $code .= $w_raw->($str);
         }
      }

   }

   $self->[FILENAME] ||= '<ANON>';

   fatal(
      'tts.base.parser._parse.unbalanced',
         abs($inside),
         ($inside > 0 ? 'opening' : 'closing'),
         $self->[FILENAME]
   ) if $inside;

   return $self->_wrapper( $code, $cache_id, $faker, $map_keys );
}

sub _chomp {
   # remove the unnecessary white space
   my $self = shift;
   my($str, $chomp) = @_;

   # NEXT: discard: left;  right -> left
   # PREV: discard: right; left  -> right
   my($next, $prev) = @{ $chomp };
   $next ||= CHOMP_NONE;
   $prev ||= CHOMP_NONE;

   my $left_collapse  = ( $next & COLLAPSE_ALL ) || ( $next & COLLAPSE_RIGHT);
   my $left_chomp     = ( $next & CHOMP_ALL    ) || ( $next & CHOMP_RIGHT   );

   my $right_collapse = ( $prev & COLLAPSE_ALL ) || ( $prev & COLLAPSE_LEFT );
   my $right_chomp    = ( $prev & CHOMP_ALL    ) || ( $prev & CHOMP_LEFT    );

   $str = $left_collapse  ? ltrim($str, ' ')
        : $left_chomp     ? ltrim($str)
        :                   $str
        ;

   $str = $right_collapse ? rtrim($str, ' ')
        : $right_chomp    ? rtrim($str)
        :                   $str
        ;

   return $str;
}

sub _wrapper {
   # this'll be tricky to re-implement around a template
   my $self     = shift;
   my $code     = shift;
   my $cache_id = shift;
   my $faker    = shift;
   my $map_keys = shift;
   my $buf_hash = $self->[FAKER_HASH];

   my $wrapper    = '';
   my $inside_inc = $self->[INSIDE_INCLUDE] != -1 ? 1 : 0;

   # build the anonymous sub
   if ( ! $inside_inc ) {
      # don't duplicate these if we're including something
      $wrapper .= "package " . DUMMY_CLASS . ";";
      $wrapper .= 'use strict;' if $self->[STRICT];
   }
   $wrapper .= 'sub { ';
   $wrapper .= sprintf q~local $0 = '%s';~, escape( q{'} => $self->[FILENAME] );
   if ( $self->[NEEDS_OBJECT] ) {
      --$self->[NEEDS_OBJECT];
      $wrapper .= 'my ' . $self->[FAKER_SELF] . ' = shift;';
   }
   $wrapper .= $self->[HEADER].';'             if $self->[HEADER];
   $wrapper .= "my $faker = '';";
   $wrapper .= $self->_add_stack( $cache_id )  if $self->[STACK];
   $wrapper .= "my $buf_hash = {\@_};"         if $map_keys;
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . ";return $faker;";
   $wrapper .= '}';
   # make this a capture sub if we're including
   $wrapper .= '->()' if $inside_inc;

   LOG( COMPILED => sprintf FRAGMENT_TMP, $self->_tidy($wrapper) )
      if DEBUG() > 1;
   #LOG( OUTPUT => $wrapper );
   # reset
   $self->[DEEP_RECURSION] = 0 if $self->[DEEP_RECURSION];
   return $wrapper;
}

sub _parse_mapkeys {
   my($self, $map_keys, $faker, $buf_hash) = @_;
   return undef, undef if ! $map_keys;

   my $mkc = $map_keys eq 'check';
   my $mki = $map_keys eq 'init';
   my $t   = $mki ? 'map_keys_init'
           : $mkc ? 'map_keys_check'
           :        'map_keys_default'
           ;
   my $mko = $self->_mini_compiler(
               $self->_internal( $t ) => {
                  BUF  => $faker,
                  HASH => $buf_hash,
                  KEY  => '%s',
               } => {
                  flatten => 1,
               }
            );
   return $mko, $mkc;
}

sub _add_stack {
   my $self    = shift;
   my $cs_name = shift || '<ANON TEMPLATE>';
   my $stack   = $self->[STACK] || '';

   return if lc($stack) eq 'off';

   my $check   = ($stack eq '1' || $stack eq 'yes' || $stack eq 'on')
               ? 'string'
               : $stack
               ;

   my($type, $channel) = split /:/, $check;
   $channel = ! $channel             ? 'warn'
            :   $channel eq 'buffer' ? $self->[FAKER] . ' .= '
            :                          'warn'
            ;

   foreach my $e ( $cs_name, $type, $channel ) {
      $e =~ s{'}{\\'}xmsg;
   }

   return "$channel stack( { type => '$type', name => '$cs_name' } );";
}

# TODO: unstable. consider removing this thing (also the constants)
sub _resume {
   my $self    = shift;
   my $token   = shift           || return;
   my $nostart = shift           || 0;
   my $is_code = shift           || 0;
   my $resume  = $self->[RESUME] || '';
   my $start   = $nostart ? '' : $self->[FAKER];
   my $void    = $nostart ? 0  : 1; # not a self-printing block

   if ( $token && $resume && $token !~ RESUME_MY ) {
      if (
            $token !~ RESUME_CURLIES &&
            $token !~ RESUME_ELSIF   &&
            $token !~ RESUME_ELSE    &&
            $token !~ RESUME_LOOP
      ) {
         LOG( RESUME_OK => $token ) if DEBUG() > 2;
         my $rvar        = $self->_output_buffer_var('array');
         my $resume_code = RESUME_TEMPLATE;
         foreach my $replace (
            [ RVAR  => $rvar             ],
            [ TOKEN => $token            ],
            [ PID   => $self->_class_id  ],
            [ VOID  => $void             ],
         ) {
            $resume_code =~ s{ <% $replace->[0] %> }{$replace->[1]}xmsg;
         }
         return $start . $resume_code;
      }
   }

   LOG( RESUME_NOT => $token ) if DEBUG() > 2;

   return $is_code ? $token : "$start .= $token;"
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Parser - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.62_11> of C<Text::Template::Simple::Base::Parser>
released on C<9 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

Private module.

=begin CHOMPING

The tokenizer uses a cursor to mark the chomping around a RAW token. Only RAW
tokens can be chomped. Basically, a RAW token can be imagined like this:

    _________
   |N|     |P|
   |E| STR |R|
   |X|     |E|
   |T|     |V|
    ---------

It'll have two labels on sides and the content in the center. When a chomp
directive is placed to the left delimiter, this affects the previous RAW token
and when it is placed to the right delimiter, it'll affect the next RAW token.
If the previous or next is not raw, nothing will happen. You need to swap sides
when handling the chomping. i.e.: left chomping affects the right side of the
RAW, and right chomping affects the left side of the RAW. _chomp() method in
the parser swaps sides to handle chomping.
See Text::Template::Simple::Tokenizer to have an idea on how pre-parsing
happens.

=end CHOMPING

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
