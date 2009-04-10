package Text::Template::Simple::Util;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Text::Template::Simple::Constants qw( :info DIGEST_MODS );
use Carp qw( croak );

$VERSION = '0.62_13';

BEGIN {
   if ( IS_WINDOWS ) {
      local $@; # perl 5.5.4 does not seem to have a Win32.pm
      eval { require Win32; Win32->import; };
   }

   # create a wrapper for binmode() 
   if ( NEW_PERL ) {
      # older perl binmode() does not accept a second param
      eval q/
         sub binary_mode {
            my($fh, $layer) = @_;
            binmode $fh, ':' . $layer;
         }
      /;
      # should never happen
      die "Error compiling binary_mode(): $@" if $@;
   }
   else {
      *binary_mode = sub { binmode $_[0] };
   }
   @ISA         = qw( Exporter );
   %EXPORT_TAGS = (
      macro => [qw( isaref      ishref iscref                  )],
      util  => [qw( binary_mode DIGEST trim rtrim ltrim escape )],
      debug => [qw( fatal       DEBUG  LOG                     )],
   );
   @EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   @EXPORT           =  @EXPORT_OK;
}

BEGIN { require Exporter; }

my $lang = {
   error => {
      'tts.base.examine.notglob'                 => "Unknown template parameter passed as %s reference! Supported types are GLOB, PATH and STRING.",
      'tts.base.examine.notfh'                   => "This GLOB is not a filehandle",
      'tts.main.cdir'                            => "Cache dir %s does not exist!",
      'tts.main.bogus_args'                      => "Malformed add_args parameter! 'add_args' must be an arrayref!",
      'tts.main.bogus_delims'                    => "Malformed delimiters parameter! 'delimiters' must be a two element arrayref!",
      'tts.cache.opendir'                        => "Can not open cache dir (%s) for reading: %s",
      'tts.util.digest'                          => "Can not load a digest module. Disable cache or install one of these (%s or %s). Last error was: %s",
      'tts.cache.dumper'                         => "Can not dump in-memory cache! Your version of Data::Dumper (%s) does not implement the Deparse() method. Please upgrade this module!",
      'tts.cache.pformat'                        => "Parameters must be in 'param => value' format",
      'tts.cache.incache'                        => "I need an 'id' or a 'data' parameter for cache check!",
      'tts.main.dslen'                           => 'Start delimiter is smaller than 2 characters',
      'tts.main.delen'                           => 'End delimiter is smaller than 2 characters',
      'tts.main.dsws'                            => 'Start delimiter contains whitespace',
      'tts.main.dews'                            => 'End delimiter contains whitespace',
      'tts.main.import.invalid'                  => "%s isn't a valid import parameter for %s",
      'tts.main.import.undef'                    => '%s is not defined in %s',
      'tts.main.import.redefine'                 => '%s is already defined in %s',
      'tts.main.tts.args'                        => 'Nothing to compile!',
      'tts.main.connector.args'                  => 'connector(): id is missing',
      'tts.main.connector.invalid'               => 'connector(): invalid id: %s',
      'tts.main.init.thandler'                   => 'user_thandler parameter must be a CODE reference',
      'tts.main.init.include'                    => 'include_paths parameter must be a ARRAY reference',
      'tts.util.escape'                          => 'Missing the character to escape',
      'tts.util.fatal'                           => '%s is not defined as an error',
      'tts.tokenizer.new.ds'                     => 'Start delimiter is missing',
      'tts.tokenizer.new.de'                     => 'End delimiter is missing',
      'tts.tokenizer.tokenize.tmp'               => 'Template string is missing',
      'tts.io.validate.type'                     => 'No type specified',
      'tts.io.validate.path'                     => 'No path specified',
      'tts.io.validate.file'                     => 'validate(file) is not yet implemented',
      'tts.io.layer.fh'                          => 'Filehandle is absent',
      'tts.io.slurp.open'                        => "Error opening '%s' for reading: %s",
      'tts.caller.stack.hash'                    => 'Parameters to stack() must be a HASH',
      'tts.caller.stack.type'                    => 'Unknown caller stack type: %s',
      'tts.caller._text_table.module'            => "Caller stack type 'text_table' requires Text::Table: %s",
      'tts.cache.new.parent'                     => 'Parent object is missing',
      'tts.cache.dumper.hash'                    => 'Parameters to dumper() must be a HASHref',
      'tts.cache.dumper.type'                    => "Dumper type '%s' is not valid",
      'tts.cache.develsize.buggy'                => 'Your Devel::Size version (%s) has a known bug. Upgrade Devel::Size to 0.72 or newer or do not use the size() method',
      'tts.cache.develsize.total'                => 'Devel::Size::total_size(): %s',
      'tts.cache.hit.meta'                       => 'Can not get meta data: %s',
      'tts.cache.hit.cache'                      => 'Error loading from disk cache: %s',
      'tts.cache.populate.write'                 => 'Error writing disk-cache %s : %s',
      'tts.base.compiler._compile.notmp'         => 'No template specified',
      'tts.base.compiler._compile.param'         => 'params must be an arrayref!',
      'tts.base.compiler._compile.opt'           => 'opts must be a hashref!',
      'tts.base.compiler._wrap_compile.parsed'   => 'nothing to compile',
      'tts.base.compiler._mini_compiler.notmp'   => '_mini_compiler(): missing the template',
      'tts.base.compiler._mini_compiler.noparam' => '_mini_compiler(): missing the parameters',
      'tts.base.compiler._mini_compiler.opt'     => '_mini_compiler(): options must be a hash',
      'tts.base.compiler._mini_compiler.param'   => '_mini_compiler(): parameters must be a HASH',
      'tts.base.examine._examine_type.ftype'     => 'ARRAY does not contain the type',
      'tts.base.examine._examine_type.fthing'    => 'ARRAY does not contain the data',
      'tts.base.examine._examine_type.extra'     => 'Type array has unknown extra fields',
      'tts.base.examine._examine_type.unknown'   => 'Unknown first argument of %s type to compile()',
      'tts.base.include._include.unknown'        => 'Unknown include type: %s',
      'tts.base.parser._internal.id'             => '_internal(): id is missing',
      'tts.base.parser._internal.rv'             => '_internal(): id is invalid',
      'tts.base.parser._parse.unbalanced'        => '%d unbalanced %s delimiter(s) in template %s',
      'tts.cache.id.generate.data'               => "Can't generate id without data!",
      'tts.cache.id._custom.data'                => "Can't generate id without data!",
   },
};

my $DEBUG = 0;  # Disabled by default
my $DIGEST;     # Will hold digester class name.

sub isaref { $_[0] && ref($_[0]) && ref($_[0]) eq 'ARRAY' };
sub ishref { $_[0] && ref($_[0]) && ref($_[0]) eq 'HASH'  };
sub iscref { $_[0] && ref($_[0]) && ref($_[0]) eq 'CODE'  };

sub fatal  {
   my $ID  = shift;
   my $str = $lang->{error}{$ID}
             || croak sprintf( $lang->{error}{'tts.util.fatal'}, $ID );
   croak @_ ? sprintf($str, @_) : $str;
}

sub escape {
   my $c = shift || fatal('tts.util.escape');
   my $s = shift;
   return $s if ! $s; # false or undef
   my $e = quotemeta $c;
      $s =~ s{$e}{\\$c}xmsg;
      $s;
}

sub trim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || '';
      $s =~ s{\A \s+   }{$extra}xms;
      $s =~ s{   \s+ \z}{$extra}xms;
   return $s;
}

sub ltrim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || '';
      $s =~ s{\A \s+ }{$extra}xms;
   return $s;
}

sub rtrim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || '';
      $s =~ s{ \s+ \z}{$extra}xms;
   return $s;
}

sub DEBUG {
   my $thing = shift;

   # so that one can use: $self->DEBUG or DEBUG
   $thing = shift if _is_parent_object( $thing );

   $DEBUG = $thing+0 if defined $thing; # must be numeric
   $DEBUG;
}

sub DIGEST {
   return $DIGEST->new if $DIGEST;

   local $SIG{__DIE__};
   # local $@;
   my $file;
   foreach my $mod ( DIGEST_MODS ) {
     ($file  = $mod) =~ s{::}{/}xmsog;
      $file .= '.pm';
      eval { require $file; };
      if ( $@ ) {
         LOG( FAILED => "$mod - $file" ) if DEBUG();
         next;
      }
      $DIGEST = $mod;
      last;
   }

   if ( not $DIGEST ) {
      my @report = DIGEST_MODS;
      my $last   = pop @report;
      fatal( 'tts.util.digest' => join(', ', @report), $last, $@ );
   }

   LOG( DIGESTER => $DIGEST ) if DEBUG();
   return $DIGEST->new;
}

sub LOG {
   return MYLOG( @_ ) if defined &MYLOG;
   my $self    = shift if ref( $_[0] );
   my $id      = shift;
   my $message = shift;
      $id      = 'DEBUG'        if not defined $id;
      $message = '<NO MESSAGE>' if not defined $message;
      $id      =~ s{_}{ }xmsg;
   warn sprintf( "[ % 15s ] %s\n", $id, $message );
}

sub _is_parent_object {
   return 0 if not defined $_[0];
   return 1 if         ref $_[0];
   return 1 if             $_[0] eq __PACKAGE__;
   return 1 if             $_[0] eq PARENT;
   return 0;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Util - Utility functions

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.62_13> of C<Text::Template::Simple::Util>
released on C<10 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

Contains utility functions for Text::Template::Simple.

=head1 FUNCTIONS

=head2 DEBUG

Returns the debug status.

=head2 DIGEST

Returns the digester object.

=head2 binary_mode FH, LAYER

Sets the I/O layer of FH in moern perls, only sets binmode on FH otherwise.

=head2 fatal ID [, PARAMS]

Internal method.

=head2 isaref THING

Returns true if C<THING> is an ARRAY.

=head2 ishref THING

Returns true if C<THING> is a HASH.

=head2 iscref THING

Returns true if C<THING> is a CODE.

=head2 trim STRING

Returns the trimmed version of the C<STRING>.

=head2 ltrim STRING

Returns the left trimmed version of the C<STRING>.

=head2 rtrim STRING

Returns the right trimmed version of the C<STRING>.

=head2 escape CHAR, STRING

Escapes all occurrances of C<CHAR> in C<STRING> with backslashes.

=head1 OVERRIDABLE FUNCTIONS

=head2 LOG

If debugging mode is enabled in Text::Template::Simple, all
debugging messages will be captured by this function and will
be printed to C<STDERR>.

If a sub named C<Text::Template::Simple::Util::MYLOG> is defined,
then all calls to C<LOG> will be redirected to this sub. If you want to
save the debugging messages to a file or to a database, you must define
the C<MYLOG> sub.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
