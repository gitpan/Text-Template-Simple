package Text::Template::Simple::Cache::ID;
use strict;
use vars qw($VERSION);
use overload q{""} => 'get';
use Text::Template::Simple::Constants qw( MAX_FL RE_INVALID_CID );
use Text::Template::Simple::Util      qw( LOG DEBUG DIGEST fatal );

$VERSION = '0.79_09';

sub new {
   my $class = shift;
   my $self  = bless do { \my $anon }, $class;
   return $self;
}

sub get { my $self = shift; $$self }
sub set { my $self = shift; $$self = shift if defined $_[0]; return; }

sub generate { # cache id generator
   my($self, $data, $custom, $regex) = @_;

   if ( ! $data ) {
      fatal('tts.cache.id.generate.data') if ! defined $data;
      LOG( IDGEN => "Generating ID from empty data" ) if DEBUG;
   }

   $self->set(
      $custom ? $self->_custom( $data, $regex )
              : $self->DIGEST->add( $data )->hexdigest
   );
   $self->get;
}

sub _custom {
   my $self  = shift;
   my $data  = shift or fatal('tts.cache.id._custom.data');
   my $regex = shift || RE_INVALID_CID;
      $data  =~ s{$regex}{_}xmsg; # remove bogus characters
   my $len   = length $data;
   # limit file name length
   $data = substr $data, $len - MAX_FL, MAX_FL if $len > MAX_FL;
   return $data;
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG();
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Cache::ID - Cache ID generator

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.79_09> of C<Text::Template::Simple::Cache::ID>
released on C<7 August 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

TODO

=head1 METHODS

=head2 new

Constructor

=head2 generate DATA [, CUSTOM, INVALID_CHARS_REGEX ]

Generates an unique cache id for the supplied data.

=head2 get

Returns the generated cache ID.

=head2 set

Set the cache ID.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2009 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
