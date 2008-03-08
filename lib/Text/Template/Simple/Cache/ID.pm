package Text::Template::Simple::Cache::ID;
use strict;
use vars qw($VERSION);
use overload q{""} => 'get';
use Text::Template::Simple::Constants qw( MAX_FL );
use Text::Template::Simple::Util      qw( DIGEST );
use Carp qw( croak );

my $RE_INVALID = qr{[^A-Za-z_0-9]};

sub new {
   bless do {\my $anon}, shift;
}

sub get { my $self = shift; $$self }
sub set { my $self = shift; $$self = shift if defined $_[0]; return; }

sub generate { # cache id generator
   my $self   = shift;
   my $data   = shift or croak "Can't generate id without data!";
   my $custom = shift;
   my $regex  = shift;
   $self->set(
      $custom ? $self->_custom( $data, $regex )
              : $self->DIGEST->add( $data )->hexdigest
   );
   $self->get;
}

sub _custom {
   my $self  = shift;
   my $data  = shift or croak "Can't generate id without data!";
   my $regex = shift || $RE_INVALID;
      $data  =~ s{$regex}{_}xmsg; # remove bogus characters
   my $len   = length( $data );
   if ( $len > MAX_FL ) { # limit file name length
      $data = substr $data, $len - MAX_FL, MAX_FL;
   }
   return $data;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Cache::ID - Cache ID generator

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 new

=head2 generate


=head2 get


=head2 set

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
