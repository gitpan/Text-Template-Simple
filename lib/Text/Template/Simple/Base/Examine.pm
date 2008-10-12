package Text::Template::Simple::Base::Examine;
use strict;
use vars qw($VERSION);
use Carp qw( croak );
use Text::Template::Simple::Util;
use Text::Template::Simple::Constants;

$VERSION = '0.62_05';

sub _examine {
   my $self   = shift;
   my $TMP    = shift;
   my($type, $thing) = $self->_examine_type( $TMP );
   my $rv;

   if ( $type eq 'ERROR' ) {
      $rv           = $thing;
      $self->[TYPE] = $type;
   }
   elsif ( $type eq 'GLOB' ) {
      $rv           = $self->_examine_glob( $thing );
      $self->[TYPE] = 'GLOB';
   }
   else {
      if ( $type eq 'FILE' || $self->io->is_file( $thing ) ) {
         $rv                = $self->io->slurp(   $thing );
         $self->[TYPE]      = 'FILE';
         $self->[TYPE_FILE] = $thing;
      }
      else {
         # give it a last chance, before falling back to string
         my $e =  do {
                     $type eq 'STRING' ? undef
                                       : $self->_file_exists( $thing );
                  };
         if ( $e ) {
            $rv                = $self->io->slurp( $e );
            $self->[TYPE]      = 'FILE';
            $self->[TYPE_FILE] = $e;
         }
         else {
            $rv                = $thing;
            $self->[TYPE]      = 'STRING';
         }
      }
   }

   LOG( EXAMINE => $self->[TYPE]."; LENGTH: ".length($rv) ) if DEBUG();
   return $rv;
}

sub _examine_glob {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;
   croak fatal(  NOTGLOB => $ref ) if $ref ne 'GLOB';
   croak fatal( 'NOTFH'          ) if not  fileno $TMP;
   return $self->io->slurp( $TMP );
}

sub _examine_type {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;

   return ''   => $TMP if ! $ref;
   return GLOB => $TMP if   $ref eq 'GLOB';

   if ( isaref( $TMP ) ) {
      my $ftype  = shift @{ $TMP } || croak "ARRAY does not contain the type";
      my $fthing = shift @{ $TMP } || croak "ARRAY does not contain the data";
      croak "ARRAY overflowed" if @{ $TMP } > 0;
      return uc $ftype, $fthing;
   }

   croak "Unknown first argument of $ref type to compile()";
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Examine - Base class for Text::Template::Simple

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
