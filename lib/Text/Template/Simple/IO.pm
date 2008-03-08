package Text::Template::Simple::IO;
use strict;
use vars qw($VERSION);
use constant IO_PARENT => 0;
use Text::Template::Simple::Constants;
use Text::Template::Simple::Util qw( DEBUG LOG ishref binary_mode );
use Text::Template::Simple::Cache::ID;
use Carp qw( croak );

$VERSION = '0.51';

sub new {
   my $class  = shift;
   my $parent = shift || croak "Parent object is missing";
   my $self   = [undef];
   bless $self, $class;
   $self->[IO_PARENT] = $parent;
   $self;
}

sub validate {
   my $self = shift;
   my $type = shift || croak "No type specified";
   my $path = shift || croak "No path specified";
   if ( $type eq 'dir' ) {
      require File::Spec;
      $path = File::Spec->canonpath( $path );
      my $wdir;
      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $path );
         if( Win32::GetLastError() ) {
            LOG( FAIL => "Win32::GetFullPathName( $path ): $^E" ) if DEBUG();
            $wdir = ''; # croak "Win32::GetFullPathName: $^E";
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
   else {
      croak "validate(file) is not yet implemented";
   }
}

sub layer {
   return if ! NEW_PERL;
   my $self   = shift;
   my $parent = $self->[IO_PARENT];
   my $fh     = shift || croak "layer(): Filehandle is absent";
   my $layer  = $parent->[IOLAYER]; # || croak "_iolayer(): I/O Layer is absent";
   binary_mode( $fh, $layer ) if $parent->[IOLAYER];
   return;
}

sub slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my $fh   = IO::File->new;
   $fh->open($file, 'r') or croak "Error opening $file for reading: $!";
   flock $fh, Fcntl::LOCK_SH() if IS_FLOCK;
   $self->layer( $fh );
   local $/;
   my $tmp = <$fh>;
   flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
   $fh->close;
   return $tmp;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG;
   @{$self} = ();
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple::IO - Text::Template::Simple I/O

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 new

=head2 layer

=head2 slurp

=head2 validate

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
