package Text::Template::Simple::Base::Examine;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.62_12';

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
      $self->[TYPE] = $type;
   }
   else {
      if ( my $path = $self->_file_exists( $thing ) ) {
         $rv                = $self->io->slurp( $path );
         $self->[TYPE]      = 'FILE';
         $self->[TYPE_FILE] = $path;
      }
      else {
         # just die if file is absent, but user forced the type as FILE
         $self->io->slurp( $thing ) if $type eq 'FILE';
         $rv           = $thing;
         $self->[TYPE] = 'STRING';
      }
   }

   LOG( EXAMINE => $self->[TYPE]."; LENGTH: ".length($rv) ) if DEBUG();
   return $rv;
}

sub _examine_glob {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;
   fatal( 'tts.base.examine.notglob' => $ref ) if $ref ne 'GLOB';
   fatal( 'tts.base.examine.notfh'           ) if not  fileno $TMP;
   return $self->io->slurp( $TMP );
}

sub _examine_type {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;

   return ''   => $TMP if ! $ref;
   return GLOB => $TMP if   $ref eq 'GLOB';

   if ( isaref( $TMP ) ) {
      my $ftype  = shift @{ $TMP } || fatal('tts.base.examine._examine_type.ftype');
      my $fthing = shift @{ $TMP } || fatal('tts.base.examine._examine_type.fthing');
      fatal('tts.base.examine._examine_type.extra') if @{ $TMP } > 0;
      return uc $ftype, $fthing;
   }

   fatal('tts.base.examine._examine_type.unknown', $ref);
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Examine - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.62_12> of C<Text::Template::Simple::Base::Examine>
released on C<10 April 2009>.

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
