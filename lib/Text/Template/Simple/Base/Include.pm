package Text::Template::Simple::Base::Include;
use strict;
use vars qw($VERSION);
use Carp qw( croak );
use Text::Template::Simple::Util;
use Text::Template::Simple::Constants;

$VERSION = '0.62_05';

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
      LOG( DEEP_RECURSION => $file ) if DEBUG;
      $error = escape '~' => $error;
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

   croak "Unknown include type: $type" if not $known;

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

   if ( -d $file ) {
      $file = escape '~' => $file;
      return "q~$err '$file' is a directory~";
   }

   if ( DEBUG ) {
      require Text::Template::Simple::Tokenizer;
      my $toke = Text::Template::Simple::Tokenizer->new;
      LOG( INCLUDE => $toke->_visualize_tid($type) . " => '$file'" );
   }

   my $text;
   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG();
      return $rv;
   }
   else {
      eval { $text = $self->io->slurp($file) };
      return "q~$err $@~" if $@;
   }

   return $self->_include_dynamic( $file, $text, $err) if $is_dynamic;
   return $self->_include_static(  $file, $text, $err);
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

   # croak "You can not pass parameters to static includes"
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
