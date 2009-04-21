package Text::Template::Simple::IO;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util qw( DEBUG LOG ishref binary_mode fatal );

$VERSION = '0.62_15';

sub new {
   my $class = shift;
   my $layer = shift;
   my $self  = bless do { \my $anon }, $class;
   $$self    = $layer if defined $layer;
   $self;
}

sub validate {
   my $self = shift;
   my $type = shift || fatal('tts.io.validate.type');
   my $path = shift || fatal('tts.io.validate.path');

   if ( $type eq 'dir' ) {
      require File::Spec;
      $path = File::Spec->canonpath( $path );
      my $wdir;

      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $path );
         if( Win32::GetLastError() ) {
            LOG( FAIL => "Win32::GetFullPathName( $path ): $^E" ) if DEBUG();
            $wdir = ''; # die "Win32::GetFullPathName: $^E";
         }
         else {
            my $ok = -e $wdir && -d _;
            $wdir  = '' if not $ok;
         }
      }

      $path = $wdir if $wdir;
      my $ok = -e $path && -d _;
      return if not $ok;
      return $path;
   }

   fatal('tts.io.validate.file');
}

sub layer {
   return if ! NEW_PERL;
   my $self   = shift;
   my $fh     = shift || fatal('tts.io.layer.fh');
   my $layer  = $$self;
   binary_mode( $fh, $layer ) if $layer;
   return;
}

sub slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my($fh, $seek);
   LOG(IO_SLURP => $file) if DEBUG();

   if ( fileno $file ) {
      $fh   = $file;
      $seek = 1;
   }
   else {
      $fh = IO::File->new;
      $fh->open($file, 'r') or fatal('tts.io.slurp.open', $file, $!);
   }

   flock $fh,    Fcntl::LOCK_SH()  if IS_FLOCK;
   seek  $fh, 0, Fcntl::SEEK_SET() if IS_FLOCK && $seek;
   $self->layer( $fh ) if ! $seek; # apply the layer only if we opened this
   my $tmp = do { local $/; <$fh> };
   flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
   close $fh if ! $seek; # close only if we opened this
   return $tmp;
}

sub is_file {
   # safer than a simple "-e"
   my $self = shift;
   my $file = shift || return;
   return     ref $file               ? 0
         :        $file =~ RE_NONFILE ? 0
         : length $file >= 255        ? 0
         : ! -e   $file               ? 0
         :   -d _                     ? 0
         :                              1
         ;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG();
   $$self = undef;
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple::IO - I/O methods

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.62_15> of C<Text::Template::Simple::IO>
released on C<21 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

TODO

=head1 METHODS

=head2 new IO_LAYER

Constructor. Accepts an I/O layer name as the parameter.

=head2 layer FH

Sets the I/O layer of the supplied filehandle if there is a layer and perl
version is greater or equal to C<5.8>.

=head2 slurp FILE_PATH

Returns the contents of the supplied file as a string.

=head2 validate TYPE, PATH

C<TYPE> can either be C<dir> or C<file>. Returns the corrected path if
it is valid, C<undef> otherwise.

=head2 is_file THING

Test if C<THING> is a file.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
