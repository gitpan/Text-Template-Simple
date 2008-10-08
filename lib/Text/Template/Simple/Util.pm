package Text::Template::Simple::Util;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Text::Template::Simple::Constants qw( :info DIGEST_MODS );
use Carp qw( croak );

$VERSION = '0.60';

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
      die "Error compiling binary_mode(): $@" if $@;
   }
   else {
      *binary_mode = sub { binmode $_[0] };
   }
}

@ISA         = qw( Exporter );
%EXPORT_TAGS = (
   macro => [qw( isaref      ishref      )],
   util  => [qw( binary_mode DIGEST trim rtrim ltrim escape )],
   debug => [qw( fatal       DEBUG  LOG  )],
);
@EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;
@EXPORT           =  @EXPORT_OK;

my %ERROR = (
   NOTGLOB  => "Unknown template parameter passed as %s reference! Supported "
              ."types are GLOB, PATH and STRING.",
   NOTFH    => "This GLOB is not a filehandle",
   CDIR     => "Cache dir %s does not exist!",
   ARGS     => "Malformed add_args parameter! 'add_args' must be an arrayref!",
   DELIMS   => "Malformed delimiters parameter! 'delimiters' must be a two "
              ."element arrayref!",
   CDIROPEN => "Can not open cache dir (%s) for reading: %s",
   DIGEST   => "Can not load a digest module. Disable cache or install one "
              ."of these (%s or %s). Last error was: %s",
   DUMPER   => "Can not dump in-memory cache! Your version of Data::Dumper "
              ."(%s) does not implement the Deparse() method. "
              ."Please upgrade this module!",
   PFORMAT  => "Parameters must be in 'param => value' format",
   INCACHE  => "I need an 'id' or a 'data' parameter for cache check!",
   DSLEN    => "Start delimiter is smaller than 2 characters",
   DELEN    => "End delimiter is smaller than 2 characters",
   DSWS     => "Start delimiter contains whitespace",
   DEWS     => "End delimiter contains whitespace",
);

my $DEBUG = 0;  # Disabled by default
my $DIGEST;     # Will hold digester class name.

sub isaref { $_[0] && ref($_[0]) && ref($_[0]) eq 'ARRAY' };

sub ishref { $_[0] && ref($_[0]) && ref($_[0]) eq 'HASH'  };

sub fatal  {
   my $ID  = shift;
   my $str = $ERROR{$ID} || croak "$ID is not defined as an error";
   return $str if not @_;
   return sprintf $str, @_;
}

sub escape {
   my $c = shift || die "Missing the character to escape";
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
      croak fatal( DIGEST => join(', ', @report), $last, $@ );
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
