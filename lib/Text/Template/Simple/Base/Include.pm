package Text::Template::Simple::Base::Include;
use strict;
use warnings;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.82';

sub _include_no_monolith {
   # no monolith eh?
   my($self, $type, $file, $opt) = @_;

   my $rv   =  $self->_mini_compiler(
                  $self->_internal('no_monolith') => {
                     OBJECT => $self->[FAKER_SELF],
                     FILE   => escape(q{~} => $file),
                     TYPE   => escape(q{~} => $type),
                  } => {
                     flatten => 1,
                  }
               );
   ++$self->[NEEDS_OBJECT];
   return $rv;
}

sub _include_static {
   my($self, $file, $text, $err, $opt) = @_;
   return $self->[MONOLITH]
        ? 'q~' . escape(q{~} => $text) . q{~;}
        : $self->_include_no_monolith( T_STATIC, $file, $opt )
        ;
}

sub _include_dynamic {
   my($self, $file, $text, $err, $opt) = @_;
   my $rv   = EMPTY_STRING;

   ++$self->[INSIDE_INCLUDE];
   $self->[COUNTER_INCLUDE] ||= {};

   # ++$self->[COUNTER_INCLUDE]{ $file } if $self->[TYPE_FILE] eq $file;

   if ( ++$self->[COUNTER_INCLUDE]{ $file } >= MAX_RECURSION ) {
      # failsafe
      $self->[DEEP_RECURSION] = 1;
      LOG( DEEP_RECURSION => $file ) if DEBUG;
      my $w = L( warning => 'tts.base.include.dynamic.recursion',
                            $err, MAX_RECURSION, $file );
      $rv .= sprintf 'q~%s~', escape( q{~} => $w );
   }
   else {
      # local stuff is for file name access through $0 in templates
      $rv .= $self->[MONOLITH]
           ? $self->_include_dynamic_monolith( $file, $text )
           : $self->_include_no_monolith( T_DYNAMIC, $file, $opt )
           ;
   }

   --$self->[INSIDE_INCLUDE]; # critical: always adjust this
   return $rv;
}

sub _include_dynamic_monolith {
   my($self,$file, $text) = @_;
   my $old = $self->[FILENAME];
   $self->[FILENAME] = $file;
   my $result = $self->_parse( $text );
   $self->[FILENAME] = $old;
   return $result;
}

sub include {
   my $self       = shift;
   my $type       = shift || 0;
   my $file       = shift;
   my $opt        = shift;
   my $is_static  = T_STATIC  == $type ? 1 : 0;
   my $is_dynamic = T_DYNAMIC == $type ? 1 : 0;
   my $known      = $is_static || $is_dynamic;

   fatal('tts.base.include._include.unknown', $type) if not $known;

   $file = trim $file;

   my $err    = $self->_include_error( $type );
   my $exists = $self->io->file_exists( $file );
   my $interpolate;

   if ( $exists ) {
      $file        = $exists; # file path correction
      $interpolate = 0;
   }
   else {
      $interpolate = 1; # just guessing ...
      return "qq~$err Interpolated includes don't work under monolith option. "
            .q{Please disable monolith and use the 'SHARE' directive in the}
            ." include command: $file~"
         if $self->[MONOLITH];
   }

   return "q~$err '" . escape(q{~} => $file) . q{' is a directory~}
      if $self->io->is_dir( $file );

   if ( DEBUG ) {
      require Text::Template::Simple::Tokenizer;
      my $toke =  Text::Template::Simple::Tokenizer->new(
                     @{ $self->[DELIMITERS] },
                     $self->[PRE_CHOMP],
                     $self->[POST_CHOMP]
                  );
      LOG( INCLUDE => $toke->_visualize_tid($type) . " => '$file'" );
   }

   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG;
      return $rv;
   }

   my $text = eval { $self->io->slurp($file); };
   return "q~$err $@~" if $@;

   my $meth = '_include_' . ($is_dynamic ? 'dynamic' : 'static');
   return $self->$meth( $file, $text, $err, $opt );
}

sub _interpolate {
   my $self   = shift;
   my $file   = shift;
   my $type   = shift;
   my $etitle = $self->_include_error($type);

   # so that, you can pass parameters, apply filters etc.
   my %inc = (INCLUDE => map { trim $_ } split RE_PIPE_SPLIT, $file );

   if ( $self->io->file_exists( $inc{INCLUDE} ) ) {
      # well... constantly working around :p
      $inc{INCLUDE} = qq{'$inc{INCLUDE}'};
   }

   # die "You can not pass parameters to static includes"
   #    if $inc{PARAM} && T_STATIC  == $type;

   my $filter = $inc{FILTER} ? escape( q{'} => $inc{FILTER} ) : EMPTY_STRING;

   if ( $inc{SHARE} ) {
      my @vars = map { trim $_ } split RE_FILTER_SPLIT, $inc{SHARE};
      my %type = qw(
                     @   ARRAY
                     %   HASH
                     *   GLOB
                     \   REFERENCE
                  );
      my @buf;
      foreach my $var ( @vars ) {
         if ( $var !~ m{ \A \$ }xms ) {
            my($char) = $var =~ m{ \A (.) }xms;
            my $type_name  = $type{ $char } || '<UNKNOWN>';
            fatal('tts.base.include._interpolate.bogus_share', $type_name, $var);
         }
         $var =~ tr/;//d;
         push @buf, $var;
      }
      $inc{SHARE} = join q{,}, @buf;
   }

   my $share = $inc{SHARE} ? sprintf(q{'%s', %s}, ($inc{SHARE}) x 2) : 'undef';
   my $rv = $self->_mini_compiler(
               $self->_internal('sub_include') => {
                  OBJECT      => $self->[FAKER_SELF],
                  INCLUDE     => escape( q{'} => $inc{INCLUDE} ),
                  ERROR_TITLE => escape( q{'} => $etitle ),
                  TYPE        => $type,
                  PARAMS      => $inc{PARAM} ? qq{[$inc{PARAM}]} : 'undef',
                  FILTER      => $filter,
                  SHARE       => $share,
               } => {
                  flatten => 1,
               }
            );

   return $rv;
}

sub _include_error {
   my $self  = shift;
   my $type  = shift;
   my $val   = T_DYNAMIC == $type ? 'dynamic'
             : T_STATIC  == $type ? 'static'
             :                      'unknown'
             ;
   my $title = sprintf '[ %s include error ]', $val;
   return $title;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Include - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 METHODS

=head2 include

=head1 DESCRIPTION

This document describes version C<0.82> of C<Text::Template::Simple::Base::Include>
released on C<30 May 2010>.

Private module.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2010 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.1 or, 
at your option, any later version of Perl 5 you may have available.

=cut
