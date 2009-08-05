package Text::Template::Simple::Base::Compiler;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.79_06';

sub _compiler { shift->[SAFE] ? COMPILER_SAFE : COMPILER }

sub _compile {
   my $self  = shift;
   my $tmpx  = shift || fatal('tts.base.compiler._compile.notmp');
   my $param = shift || [];
   my $opt   = shift || {};

   fatal('tts.base.compiler._compile.param') if not isaref($param);
   fatal('tts.base.compiler._compile.opt')   if not ishref($opt  );

   # set defaults
   $opt->{id}       ||= ''; # id is AUTO
   $opt->{map_keys} ||= 0;  # use normal behavior
   $opt->{chkmt}    ||= 0;  # check mtime of file template?
   $opt->{_sub_inc} ||= 0;  # are we called from a dynamic include op?
   $opt->{_filter}  ||= ''; # any filters?

   my $tmp = $self->_examine( $tmpx );
   return $tmp if $self->[TYPE] eq 'ERROR';

   if ( $opt->{_sub_inc} ) {
      # TODO:generate a single error handler for includes, merge with _include()
      # tmpx is a "file" included from an upper level compile()
      my $etitle = $self->_include_error( T_DYNAMIC );
      my $exists = $self->io->file_exists( $tmpx );
      return $etitle . " '$tmpx' is not a file" if not $exists;
      # TODO: remove this second call somehow, reduce  to a single call
      $tmp = $self->_examine( $exists ); # re-examine
      $self->[NEEDS_OBJECT]++; # interpolated includes will need that
   }

   if ( $opt->{chkmt} ) {
      $opt->{chkmt} = $self->[TYPE] eq 'FILE' ? (stat $tmpx)[STAT_MTIME]
                    : do {
                        DEBUG && LOG(DISABLE_MT =>
                                     "Disabling chkmt. Template is not a file");
                        0;
                     }
   }

   LOG( COMPILE => $opt->{id} ) if DEBUG && defined $opt->{id};

   my($CODE, $ok);
   my $cache_id = '';

   my $as_is = $opt->{_sub_inc} && $opt->{_sub_inc} == T_STATIC;

   # first element is the shared names. if it's not defined, then there
   # are no shared variables from top level
   delete $opt->{_share}
      if isaref($opt->{_share}) && ! defined $opt->{_share}[0];

   if ( $self->[CACHE] ) {
      my $method = $opt->{id};
      my @args   = (! $method || $method eq 'AUTO') ? ( $tmp              )
                 :                                    ( $method, 'custom' )
                 ;
      $cache_id  = $self->connector('Cache::ID')->new->generate( @args );

      # prevent overwriting the compiled version in cache
      # since we need the non-compiled version
      $cache_id .= '_1' if $as_is;

      if ( $CODE = $self->cache->hit( $cache_id, $opt->{chkmt} ) ) {
         LOG( CACHE_HIT =>  $cache_id ) if DEBUG();
         $ok = 1;
      }
   }

   $self->cache->id( $cache_id ); # if $cache_id;
   $self->[FILENAME] = $self->[TYPE] eq 'FILE' ? $tmpx : $self->cache->id;

   my($shead, @sparam) = $opt->{_share} ? @{$opt->{_share}} : ();

   LOG(
      SHARED_VARS => "Adding shared variables ($shead) from a dynamic include"
   ) if DEBUG && $shead;

   if ( not $ok ) {
      # we have a cache miss; parse and compile
      LOG( CACHE_MISS => $cache_id ) if DEBUG();

      my $shared;
      if ( $shead ) {
         my $param = join ',', ('shift') x @sparam;
         $shared = sprintf qq~my(%s) = (%s);~, $shead, $param;
      }

      local $self->[HEADER] = do {
         my $old = $self->[HEADER] || '';
         $shared . ';' . $old
      } if $shared;

      my %popt   = ( %{ $opt }, cache_id => $cache_id, as_is => $as_is );
      my $parsed = $self->_parse( $tmp, \%popt );
      $CODE      = $self->cache->populate( $cache_id, $parsed, $opt->{chkmt} );
   }

   my @args;
   push @args, $self   if $self->[NEEDS_OBJECT]; # must be the first
   push @args, @sparam if @sparam;
   push @args, @{ $self->[ADD_ARGS] } if $self->[ADD_ARGS];
   push @args, @{ $param };
   my $out = $CODE->( @args );

   $self->_call_filters( \$out, split RE_FILTER_SPLIT, $opt->{_filter} )
      if $opt->{_filter};

   return $out;
}

sub _call_filters {
   my $self    = shift;
   my $oref    = shift;
   my @filters = @_;
   my $fname   = $self->[FILENAME];

   APPLY_FILTERS: foreach my $filter ( @filters ) {
      my $fref = DUMMY_CLASS->can( "filter_" . $filter );
      if ( ! $fref ) {
         $$oref .= "\n[ filter warning ] Can not apply undefined filter"
                .  " $filter to $fname\n";
         next;
      }
      $fref->( $self, $oref );
   }

   return;
}

sub _wrap_compile {
   my $self   = shift;
   my $parsed = shift or fatal('tts.base.compiler._wrap_compile.parsed');
   LOG( CACHE_ID => $self->cache->id ) if $self->[WARN_IDS] && $self->cache->id;
   LOG( COMPILER => $self->[SAFE] ? 'Safe' : 'Normal' ) if DEBUG();
   my($CODE, $error);

   $CODE = $self->_compiler->_compile($parsed);

   if( $error = $@ ) {
      my $error2;
      $error .= $error2 if $error2;
   }

   return $CODE, $error;
}

sub _mini_compiler {
   # little dumb compiler for internal templates
   my $self     = shift;
   my $template = shift || fatal('tts.base.compiler._mini_compiler.notmp');
   my $param    = shift || fatal('tts.base.compiler._mini_compiler.noparam');
   my $opt      = shift || {};

   fatal('tts.base.compiler._mini_compiler.opt')   if ! ishref($opt  );
   fatal('tts.base.compiler._mini_compiler.param') if ! ishref($param);

   foreach my $var ( keys %{ $param } ) {
      $template =~ s[<%\Q$var\E%>][$param->{$var}]xmsg;
   }

   $template =~ s{\s+}{ }xmsg if $opt->{flatten}; # remove extra spaces
   return $template;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Compiler - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.79_06> of C<Text::Template::Simple::Base::Compiler>
released on C<5 August 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

Private module.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2009 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
