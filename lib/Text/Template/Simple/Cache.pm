package Text::Template::Simple::Cache;
use strict;
use vars qw($VERSION);
use constant CACHE_PARENT => 0;
use Text::Template::Simple::Constants;
use Text::Template::Simple::Util qw( DEBUG LOG ishref );
use Carp qw( croak );

$VERSION = '0.54_11';

my $CACHE = {}; # in-memory template cache

sub new {
   my $class  = shift;
   my $parent = shift || croak "Parent object is missing";
   my $self   = [undef];
   bless $self, $class;
   $self->[CACHE_PARENT] = $parent;
   $self;
}

sub id {
   my $self = shift;
   $self->[CACHE_PARENT][CID] = shift if @_;
   $self->[CACHE_PARENT][CID];
}

sub type {
   my $self = shift;
   my $parent = $self->[CACHE_PARENT];
   return $parent->[CACHE] ? $parent->[CACHE_DIR] ? 'DISK'
                                                  : 'MEMORY'
                           : 'OFF';
}

sub reset {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];
   %{$CACHE}  = ();

   if ( $parent->[CACHE] && $parent->[CACHE_DIR] ) {

      my $cdir = $parent->[CACHE_DIR];
      local  *CDIRH;
      opendir CDIRH, $cdir or croak fatal( CDIROPEN => $cdir, $! );
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $file;

      while ( defined( $file = readdir CDIRH ) ) {
         next if $file !~ m{ $ext \z}xmsi;
         $file = File::Spec->catfile( $parent->[CACHE_DIR], $file );
         LOG( UNLINK => $file ) if DEBUG();
         unlink $file;
      }

      closedir CDIRH;
   }
}

sub dumper {
   my $self  = shift;
   my $type  = shift || 'structure';
   my $param = shift || {};
   croak "Parameters to dumper() must be a HASHref" if not ishref $param;
   my %valid = map { $_, $_ } qw( ids structure );
   croak "dumper type '$type' is not valid " if not $valid{ $type };
   my $method = '_dump_' . $type;
   return $self->$method( $param ); # TODO: modify the methods to accept HASH
}

sub _dump_ids {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];
   my $p      = shift;
   my $VAR    = $p->{varname} || '$CACHE_IDS';
   my @rv;

   if ( $parent->[CACHE_DIR] ) {

      require File::Find;
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my($id, @list);

      my $wanted = sub {
         return if $_ !~ m{ (.+?) $ext \z }xms;
         $id      = $1;
         $id      =~ s{.*[\\/]}{};
         push @list, $id;
      };

      File::Find::find({wanted => $wanted, no_chdir => 1}, $parent->[CACHE_DIR]);

      @rv = sort @list;

   }
   else {
      @rv = sort keys %{ $CACHE };
   }

   require Data::Dumper;
   my $d = Data::Dumper->new( [ \@rv ], [ $VAR ]);
   return $d->Dump;
}

sub _dump_structure {
   my $self    = shift;
   my $parent  = $self->[CACHE_PARENT];
   my $p       = shift;
   my $VAR     = $p->{varname} || '$CACHE';
   my $deparse = $p->{no_deparse} ? 0 : 1;
   require Data::Dumper;
   my $d;

   if ( $parent->[CACHE_DIR] ) {
      $d = Data::Dumper->new( [ $self->_dump_disk_cache ], [ $VAR ] );
   }
   else {
      $d = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
      if ( $deparse ) {
         croak fatal(DUMPER => $Data::Dumper::VERSION) if !$d->can('Deparse');
         $d->Deparse(1);
      }
   }

   my $str;
   eval { $str = $d->Dump; };

   if ( my $error = $@ ) {
      if ( $deparse && $error =~ RE_DUMP_ERROR ) {
         my $name = ref($self) . '::dump_cache';
         warn "$name: An error occurred when dumping with deparse "
             ."(are you under mod_perl?). Re-Dumping without deparse...\n";
         warn "$error\n";
         my $nd = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
         $nd->Deparse(0);
         $str = $nd->Dump;
      }
      else {
         croak $error;
      }
   }

   return $str;
}

sub _dump_disk_cache {
   require File::Find;
   require File::Spec;
   my $self    = shift;
   my $parent  = $self->[CACHE_PARENT];
   my $ext     = quotemeta CACHE_EXT;
   my $pattern = quotemeta DISK_CACHE_MARKER;
   my(%disk_cache, $id, $content, $ok, $_temp, $line);

   my $wanted = sub {
      return if $_ !~ m{(.+?) $ext \z}xms;
      $id      = $1;
      $id      =~ s{.*[\\/]}{};
      $content = $parent->io->slurp( File::Spec->canonpath($_) );
      $ok      = 0;  # reset
      $_temp   = ''; # reset

      foreach $line ( split /\n/, $content ) {
         if ( $line =~ m{$pattern}xmso ) {
            $ok = 1;
            next;
         }
         next if not $ok;
         $_temp .= $line;
      }

      $disk_cache{ $id } = {
         MTIME => (stat $_)[STAT_MTIME],
         CODE  => $_temp,
      };
   };
 
   File::Find::find({ wanted => $wanted, no_chdir => 1 }, $parent->[CACHE_DIR]);
   return \%disk_cache;
}

sub size {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];

   return 0 if not $parent->[CACHE]; # calculate only if cache is enabled

   if ( my $cdir = $parent->[CACHE_DIR] ) { # disk cache
      require File::Find;
      my $total  = 0;
      my $ext    = quotemeta CACHE_EXT;

      my $wanted = sub {
         return if $_ !~ m{ $ext \z }xms; # only calculate "our" files
         $total += (stat $_)[STAT_SIZE];
      };

      File::Find::find( { wanted => $wanted, no_chdir => 1 }, $cdir );
      return $total;

   }
   else { # in-memory cache

      local $SIG{__DIE__};
      if ( eval { require Devel::Size; 1; } ) {
         LOG( DEBUG => "Devel::Size v$Devel::Size::VERSION is loaded." )
            if DEBUG();
         my $size = eval { Devel::Size::total_size( $CACHE ) };
         die "Devel::Size::total_size(): $@" if $@;
         return $size;
      }
      else {
         warn "Failed to load Devel::Size: $@";
         return 0;
      }

   }
}

sub has {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];

   if ( not $parent->[CACHE] ) {
      LOG( DEBUG => "Cache is disabled!") if DEBUG();
      return;
   }

   croak fatal('PFORMAT') if @_ % 2;

   my %opt = @_;
   my $id  = $parent->connector('Cache::ID')->new;
   my $cid = $opt{id}   ? $id->generate($opt{id}  , 'custom')
           : $opt{data} ? $id->generate($opt{data}          )
           :              croak fatal('INCACHE');

   if ( my $cdir = $parent->[CACHE_DIR] ) {
      require File::Spec;
      return -e File::Spec->catfile( $cdir, $cid . CACHE_EXT ) ? 1 : 0;
   }
   else {
      return exists $CACHE->{ $cid } ? 1 : 0;
   }
}

sub hit {
   # TODO: return $CODE, $META;
   my $self     = shift;
   my $parent   = $self->[CACHE_PARENT];
   my $cache_id = shift;
   my $chkmt    = shift || 0;
   my($CODE, $error);

   if ( my $cdir = $parent->[CACHE_DIR] ) {
      require File::Spec;
      my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT );

      if ( -e $cache && not -d _ && -f _ ) {
         my $disk_cache = $parent->io->slurp($cache);
         my %meta;
         if ( $disk_cache =~ m{ \A \#META: (.+?) \n }xms ) {
            %meta = $self->_get_meta( $1 );
            croak "Can not get meta data: $@" if $@;
         }
         if ( my $mtime = $meta{CHKMT} ) {
            if ( $mtime != $chkmt ) {
               LOG( MTIME_DIFF => "\tOLD: $mtime\n\t\tNEW: $chkmt")
                  if DEBUG();
               return; # i.e.: Update cache
            }
         }

         ($CODE, $error) = $parent->_wrap_compile($disk_cache);
         $parent->[NEEDS_OBJECT] = $meta{NEEDS_OBJECT} if $meta{NEEDS_OBJECT};
         $parent->[FAKER_SELF]   = $meta{FAKER_SELF}   if $meta{FAKER_SELF};

         croak "Error loading from disk cache: $error" if $error;
         LOG( FILE_CACHE => '' ) if DEBUG();
         #$parent->[COUNTER]++;
         return $CODE;
      }

   }
   else {
      if ( $chkmt ) {
         my $mtime = $CACHE->{$cache_id}{MTIME} || 0;

         if ( $mtime != $chkmt ) {
            LOG( MTIME_DIFF => "\tOLD: $mtime\n\t\tNEW: $chkmt" ) if DEBUG();
            return; # i.e.: Update cache
         }

      }
      LOG( MEM_CACHE => '' ) if DEBUG();
      return $CACHE->{$cache_id}->{CODE};
   }
   return;
}

sub populate {
   my $self     = shift;
   my $parent   = $self->[CACHE_PARENT];
   my $cache_id = shift;
   my $parsed   = shift;
   my $chkmt    = shift;
   my($CODE, $error);

   if ( $parent->[CACHE] ) {
      if ( my $cdir = $parent->[CACHE_DIR] ) {
         require File::Spec;
         require Fcntl;
         require IO::File;

         my %meta = (
            CHKMT        => $chkmt,
            NEEDS_OBJECT => $parent->[NEEDS_OBJECT],
            FAKER_SELF   => $parent->[FAKER_SELF],
         );

         my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT);
         my $fh    = IO::File->new;
         $fh->open($cache, '>') or croak "Error writing disk-cache $cache : $!";
         flock $fh, Fcntl::LOCK_EX() if IS_FLOCK;
         $parent->io->layer($fh);
         print $fh '#META:' . $self->_set_meta(\%meta) . "\n",
                   sprintf( DISK_CACHE_COMMENT,
                            PARENT->_class_id, scalar localtime time),
                   $parsed; 
         flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
         close $fh;

         ($CODE, $error) = $parent->_wrap_compile($parsed);
         LOG( DISK_POPUL => $cache_id ) if DEBUG() > 2;
      } 
      else {
         $CACHE->{ $cache_id } = {}; # init
         ($CODE, $error)                       = $parent->_wrap_compile($parsed);
         $CACHE->{ $cache_id }->{CODE}         = $CODE;
         $CACHE->{ $cache_id }->{MTIME}        = $chkmt if $chkmt;
         $CACHE->{ $cache_id }->{NEEDS_OBJECT} = $parent->[NEEDS_OBJECT];
         $CACHE->{ $cache_id }->{FAKER_SELF}   = $parent->[FAKER_SELF];
         LOG( MEM_POPUL => $cache_id ) if DEBUG() > 2;
      }
   }
   else {
      ($CODE, $error) = $parent->_wrap_compile($parsed); # cache is disabled
      LOG( NC_POPUL => $cache_id ) if DEBUG() > 2;
   }

   if ( $error ) {
      my $cid    = $cache_id ? $cache_id : 'N/A';
      my $tidied = $parent->_tidy( $parsed );
      croak sprintf COMPILE_ERROR_TMP, $cid, $error, $parsed, $tidied;
   }

   $parent->[COUNTER]++;
   return $CODE;
}

sub _get_meta {
   my $self = shift;
   my $raw  = shift;
   my %meta = map { split /:/, $_ } split /\|/, $raw;
   return %meta;
}

sub _set_meta {
   my $self = shift;
   my $meta = shift;
   my $rv   = join '|', map { $_ . ':' . $meta->{ $_ } } keys %{ $meta };
   return $rv;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG;
   $self->[CACHE_PARENT] = undef;
   @{$self} = ();
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Cache - Cache manager

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

Cache manager for C<Text::Template::Simple>.

=head1 METHODS

=head2 new PARENT_OBJECT

Constructor. Accepts a C<Text::Template::Simple> object as the parameter.

=head2 type

Returns the type of the cache.

=head2 reset

Resets the in-memory cache and deletes all cache files, 
if you are using a disk cache.

=head2 dumper TYPE

   $template->cache->dumper( $type, \%opt );

C<TYPE> can either be C<structure> or C<ids>.
C<dumper> accepts some arguments as a hashref:

   $template->cache->dumper( $type, \%opt );

=over 4

=item *

varname

Controls the name of the dumped structure.

=item *

no_deparse

If you set this to a true value, deparsing will be disabled

=back

=head3 structure

Returns a string version of the dumped in-memory or disk-cache. 
Cache is dumped via L<Data::Dumper>. C<Deparse> option is enabled
for in-memory cache. 

Early versions of C<Data::Dumper> don' t have a C<Deparse>
method, so you may need to upgrade your C<Data::Dumper> or
disable deparse-ing if you want to use this method.

=head3 ids

Returns a list including the names (ids) of the templates in
the cache.

=head2 id

Gets/sets the cache id.

=head2 size

Returns the total cache (disk or memory) size in bytes. If
memory cache is used, then you must have L<Devel::Size> installed
on your system to get the size of the data structure inside memory.

=head2 has data => TEMPLATE_DATA

=head2 has id   => TEMPLATE_ID

This method can be called with C<data> or C<id> named parameter. If you 
use the two together, C<id> will be used:

   if ( $template->cache->has( id => 'e369853df766fa44e1ed0ff613f563bd' ) ) {
      print "ok!";
   }

or

   if ( $template->cache->has( data => q~Foo is <%=$bar%>~ ) ) {
      print "ok!";
   }

=head2 hit

TODO

=head2 populate

TODO

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
