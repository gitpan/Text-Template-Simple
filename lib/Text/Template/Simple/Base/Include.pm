package Text::Template::Simple::Base::Include;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.62_09';

sub _include_no_monolith {
   # no monolith eh?
   my $self = shift;
   my $type = shift;
   my $file = shift;
   my $rv   =  $self->_mini_compiler(
                  $self->_internal('no_monolith') => {
                     OBJECT => $self->[FAKER_SELF],
                     FILE   => escape('~' => $file),
                     TYPE   => escape('~' => $type),
                  } => {
                     flatten => 1,
                  }
               );
   ++$self->[NEEDS_OBJECT];
   return $rv;
}

sub _include_static {
   my($self, $file, $text, $err) = @_;
   return $self->[MONOLITH]
        ? 'q~' . escape('~' => $text) . '~;'
        : $self->_include_no_monolith( T_STATIC, $file )
        ;
}

sub _include_dynamic {
   my($self, $file, $text, $err) = @_;
   my $rv   = '';

   ++$self->[INSIDE_INCLUDE];
   $self->[COUNTER_INCLUDE] ||= {};

   # ++$self->[COUNTER_INCLUDE]{ $file } if $self->[TYPE_FILE] eq $file;

   if ( ++$self->[COUNTER_INCLUDE]{ $file } >= MAX_RECURSION ) {
      # failsafe
      my $max   = MAX_RECURSION;
      my $error = qq{$err Deep recursion (>=$max) detected in }
                . qq{the included file: $file};
      LOG( DEEP_RECURSION => $file ) if DEBUG();
      $error = escape( '~' => $error );
      $self->[DEEP_RECURSION] = 1;
      $rv .= "q~$error~";
   }
   else {
      # local stuff is for file name access through $0 in templates
      $rv .= $self->[MONOLITH]
           ? do { local $self->[FILENAME] = $file; $self->_parse( $text ) }
           : $self->_include_no_monolith( T_DYNAMIC, $file )
           ;
   }

   --$self->[INSIDE_INCLUDE]; # critical: always adjust this
   return $rv;
}


sub _include {
   my $self       = shift;
   my $type       = shift || 0;
   my $file       = shift;
   my $is_static  = T_STATIC  == $type ? 1 : 0;
   my $is_dynamic = T_DYNAMIC == $type ? 1 : 0;
   my $known      = $is_static || $is_dynamic;

   fatal('tts.base.include._include.unknown', $type) if not $known;

   $file = trim $file;

   my $err    = $self->_include_error( $type );
   my $exists = $self->_file_exists( $file );
   my $interpolate;

   if ( $exists ) {
      $file        = $exists; # file path correction
      $interpolate = 0;
   }
   else {
      $interpolate = 1; # just guessing ...
   }

   return "q~$err '" . escape('~' => $file) . "' is a directory~" if -d $file;

   if ( DEBUG() ) {
      require Text::Template::Simple::Tokenizer;
      my $toke = Text::Template::Simple::Tokenizer->new;
      LOG( INCLUDE => $toke->_visualize_tid($type) . " => '$file'" );
   }

   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG();
      return $rv;
   }

   my $text;
   eval { $text = $self->io->slurp($file); };
   return "q~$err $@~" if $@;

   my $meth = '_include_' . ($is_dynamic ? 'dynamic' : 'static');
   return $self->$meth( $file, $text, $err);
}

sub _interpolate {
   my $self   = shift;
   my $file   = shift;
   my $type   = shift;
   my $etitle = $self->_include_error($type);

   # so that, you can pass parameters, apply filters etc.
   my %inc = (INCLUDE => map { trim $_ } split RE_PIPE_SPLIT, $file );

   if ( $self->_file_exists( $inc{INCLUDE} ) ) {
      # well... constantly working around :p
      $inc{INCLUDE} = qq{'$inc{INCLUDE}'};
   }

   # die "You can not pass parameters to static includes"
   #    if $inc{PARAM} && T_STATIC  == $type;

   my $filter = $inc{FILTER} ? escape( q{'} => $inc{FILTER} ) : '';

   my $rv = $self->_mini_compiler(
               $self->_internal('sub_include') => {
                  OBJECT      => $self->[FAKER_SELF],
                  INCLUDE     => escape( q{'} => $inc{INCLUDE} ),
                  ERROR_TITLE => escape( q{'} => $etitle ),
                  TYPE        => $type,
                  PARAMS      => $inc{PARAM} ? qq{[$inc{PARAM}]} : 'undef',
                  FILTER      => $filter,
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
   my $title = '[ ' . $val . ' include error ]';
   return $title;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Include - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.62_09> of C<Text::Template::Simple::Base::Include>
released on C<8 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

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
