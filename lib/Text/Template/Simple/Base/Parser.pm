package Text::Template::Simple::Base::Parser;
use strict;
use vars qw($VERSION);
use Carp qw( croak );
use Text::Template::Simple::Util;
use Text::Template::Simple::Constants;

$VERSION = '0.54_11';

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
         undef,
         {
            _sub_inc => '<%TYPE%>'
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
   my $id   = shift            || croak "_internal(): id is missing";
   my $rv   = $INTERNAL{ $id } || croak "_internal(): id is invalid";
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

   my $w_raw = sub { ";$faker .= q~$_[0]~;" };
   my $w_cap = sub { ";$faker .= sub {" . $_[0] . "}->();"; };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $as_is;

   # fetch and walk the tree
   my($id, $str);
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $map_keys ) } ) {
      ($id, $str) = @{ $token };
      LOG( TOKEN => "$id => $str" ) if DEBUG() > 1;
      next PARSER if $id eq 'DISCARD';
      next PARSER if $id eq 'COMMENT';

      if ( $id eq 'DELIMSTART' ) { $inside++; next PARSER; }
      if ( $id eq 'DELIMEND'   ) { $inside--; next PARSER; }

      if ( $id eq 'RAW' || $id eq 'NOTADELIM' ) {
         $code .= $w_raw->($str);
      }

      elsif ( $id eq 'CODE' ) {
         $code .= $resume ? $self->_resume($str, 0, 1) : $str;
      }

      elsif ( $id eq 'CAPTURE' ) {
         $code .= $faker;
         $code .= $resume ? $self->_resume($str, RESUME_NOSTART)
                :           " .= sub { $str }->();";
      }

      elsif ( $id eq 'DYNAMIC' || $id eq 'STATIC' ) {
         $self->[NEEDS_OBJECT]++;
         $code .= $w_cap->( $self->_include($id, $str) );
      }

      elsif ( $id eq 'MAPKEY' ) {
         $code .= sprintf $mko, $mkc ? ( ($str) x 5 ) : $str;
      }

      else {
         if ( $handler ) {
            LOG( USER_THANDLER => "$id") if DEBUG;
            $code .= $handler->(
                        $self, $id ,$str, { capture => $w_cap, raw => $w_raw }
                     );
         }
         else {
            LOG( UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)")
               if DEBUG;
            $code .= $w_raw->($str);
         }
      }

   }

   $self->[FILENAME] ||= '<ANON>';

   if ( $inside ) {
      my $type = $inside > 0 ? 'opening' : 'closing';
      my $tmpl = "%d unbalanced %s delimiter(s) in template %s";
      croak sprintf( $tmpl, abs($inside), $type, $self->[FILENAME] );
   }

   return $self->_wrapper( $code, $cache_id, $faker, $map_keys );
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

Private module.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
