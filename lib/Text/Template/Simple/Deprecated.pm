package Text::Template::Simple::Deprecated;
use strict;
use vars qw($VERSION);

$VERSION = '0.52';

my $DEPRECATED = qq{THIS METHOD IS DEPRECATED AND WILL BE REMOVED IN THE FUTURE!};

sub idgen { # cache id generator
   warn "idgen(): $DEPRECATED See Text::Template::Simple::Cache::ID\n";
   my $self = shift;
   return Text::Template::Simple::Cache::ID->new->generate(@_);
}

sub custom_idgen {
   warn "custom_idgen(): $DEPRECATED See Text::Template::Simple::Cache::ID\n";
   my $self = shift;
   return Text::Template::Simple::Cache::ID->new->_custom(@_);
}

sub reset_cache {
   warn "reset_cache(): $DEPRECATED See Text::Template::Simple::Cache\n";
   my $self = shift;
   return $self->cache->reset( @_ );
}

sub dump_cache_ids {
   warn "dump_cache_ids(): $DEPRECATED See Text::Template::Simple::Cache\n";
   my $self = shift;
   return $self->cache->dumper( ids => @_ % 2 ? () : ({@_}) );
}

sub dump_cache {
   warn "dump_cache(): $DEPRECATED See Text::Template::Simple::Cache\n";
   my $self = shift;
   return $self->cache->dumper( structure => @_ % 2 ? () : ({@_}) );
}

sub cache_size {
   warn "cache_size(): $DEPRECATED See Text::Template::Simple::Cache\n";
   my $self = shift;
   return $self->cache->size( @_ );
}

sub in_cache {
   warn "in_cache(): $DEPRECATED See Text::Template::Simple::Cache\n";
   my $self = shift;
   return $self->cache->has( @_ );
}

1;

__END__

=head1 NAME

Text::Template::Simple::Deprecated - Deprecated methods

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Use the new interface. These methods will be removed in the future.

=head1 METHODS

=head2 cache_size


=head2 custom_idgen


=head2 dump_cache


=head2 dump_cache_ids


=head2 idgen


=head2 in_cache


=head2 reset_cache


=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
