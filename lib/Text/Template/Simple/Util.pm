package Text::Template::Simple::Util;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Text::Template::Simple::Constants qw( :info DIGEST_MODS );
use Carp qw( croak );

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
            binmode $fh, ':'.$layer
         }
      /;
      die "Error compiling binary_mode(): $@" if $@;
   }
   else {
      *binary_mode = sub { binmode $_[0] };
   }
}

$VERSION = '0.10';

@ISA         = qw( Exporter );
%EXPORT_TAGS = (
   macro => [qw( isaref      ishref     )],
   util  => [qw( binary_mode DIGEST     )],
   debug => [qw( fatal       DEBUG  LOG )],
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

sub DEBUG {
   my $thing = shift;

   # so that one can use: $self->DEBUG or DEBUG
   $thing = shift if _is_parent_object( $thing );

   $DEBUG = $thing if defined $thing;
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
         _LOG( FAILED => "$mod - $file" ) if DEBUG();
         next;
      }
      $DIGEST = $mod;
      last;
   }

   if ( not $DIGEST ) {
      my @report = DIGEST_MODS;
      my $last   = pop @report;
      croak _fatal( DIGEST => join(', ', @report), $last, $@ );
   }

   _LOG( DIGESTER => $DIGEST ) if DEBUG();
   return $DIGEST->new;
}

sub LOG {
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
