BEGIN { $INC{$_} = 1 for qw(Text/Template/Simple.pm Text/Template/Simple/Cache.pm Text/Template/Simple/Caller.pm Text/Template/Simple/Compiler.pm Text/Template/Simple/Constants.pm Text/Template/Simple/Dummy.pm Text/Template/Simple/IO.pm Text/Template/Simple/Tokenizer.pm Text/Template/Simple/Util.pm Text/Template/Simple/Base/Compiler.pm Text/Template/Simple/Base/Examine.pm Text/Template/Simple/Base/Include.pm Text/Template/Simple/Base/Parser.pm Text/Template/Simple/Cache/ID.pm Text/Template/Simple/Compiler/Safe.pm); }
package Text::Template::Simple;
sub ________monolith {}
package Text::Template::Simple::Cache;
sub ________monolith {}
package Text::Template::Simple::Caller;
sub ________monolith {}
package Text::Template::Simple::Compiler;
sub ________monolith {}
package Text::Template::Simple::Constants;
sub ________monolith {}
package Text::Template::Simple::Dummy;
sub ________monolith {}
package Text::Template::Simple::IO;
sub ________monolith {}
package Text::Template::Simple::Tokenizer;
sub ________monolith {}
package Text::Template::Simple::Util;
sub ________monolith {}
package Text::Template::Simple::Base::Compiler;
sub ________monolith {}
package Text::Template::Simple::Base::Examine;
sub ________monolith {}
package Text::Template::Simple::Base::Include;
sub ________monolith {}
package Text::Template::Simple::Base::Parser;
sub ________monolith {}
package Text::Template::Simple::Cache::ID;
sub ________monolith {}
package Text::Template::Simple::Compiler::Safe;
sub ________monolith {}
package Text::Template::Simple::Constants;
use strict;
use vars qw($VERSION $OID $DID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.79_03';

# object fields
BEGIN { $OID = -1 } # init object field id counter
use constant DELIMITERS       => ++$OID;
use constant AS_STRING        => ++$OID;
use constant DELETE_WS        => ++$OID;
use constant FAKER            => ++$OID;
use constant FAKER_HASH       => ++$OID;
use constant FAKER_SELF       => ++$OID;
use constant FAKER_WARN       => ++$OID;
use constant MONOLITH         => ++$OID;
use constant CACHE            => ++$OID;
use constant CACHE_DIR        => ++$OID;
use constant CACHE_OBJECT     => ++$OID;
use constant IO_OBJECT        => ++$OID;
use constant STRICT           => ++$OID;
use constant SAFE             => ++$OID;
use constant HEADER           => ++$OID;
use constant ADD_ARGS         => ++$OID;
use constant CAPTURE_WARNINGS => ++$OID;
use constant WARN_IDS         => ++$OID;
use constant TYPE             => ++$OID;
use constant TYPE_FILE        => ++$OID;
use constant COUNTER          => ++$OID;
use constant COUNTER_INCLUDE  => ++$OID;
use constant INSIDE_INCLUDE   => ++$OID;
use constant NEEDS_OBJECT     => ++$OID;
use constant CID              => ++$OID;
use constant FILENAME         => ++$OID;
use constant IOLAYER          => ++$OID;
use constant STACK            => ++$OID;
use constant USER_THANDLER    => ++$OID;
use constant DEEP_RECURSION   => ++$OID;
use constant INCLUDE_PATHS    => ++$OID;
use constant PRE_CHOMP        => ++$OID;
use constant POST_CHOMP       => ++$OID;
use constant VERBOSE_ERRORS   => ++$OID;
use constant TAINT_MODE       => ++$OID;
use constant MAXOBJFIELD      =>   $OID; # number of the last object field

# token type ids
BEGIN { $DID = 0 }
use constant T_DELIMSTART     => ++$DID;
use constant T_DELIMEND       => ++$DID;
use constant T_DISCARD        => ++$DID;
use constant T_COMMENT        => ++$DID;
use constant T_RAW            => ++$DID;
use constant T_NOTADELIM      => ++$DID;
use constant T_CODE           => ++$DID;
use constant T_CAPTURE        => ++$DID;
use constant T_DYNAMIC        => ++$DID;
use constant T_STATIC         => ++$DID;
use constant T_MAPKEY         => ++$DID;
use constant T_COMMAND        => ++$DID;
use constant T_MAXID          =>   $DID;

# settings
use constant MAX_RECURSION    => 50; # recursion limit for dynamic includes
use constant PARENT           => 'Text::Template::Simple';
use constant IS_WINDOWS       => $^O eq 'MSWin32' || $^O eq 'MSWin64';
use constant DELIM_START      => 0; # field id
use constant DELIM_END        => 1; # field id
use constant RE_NONFILE       => qr{ [ \n \r < > \* \? ] }xmso;
use constant RE_DUMP_ERROR    => qr{Can\'t locate object method "first" via package "B::SVOP"};
use constant COMPILER         => PARENT.'::Compiler'; # The compiler
use constant COMPILER_SAFE    => COMPILER.'::Safe';   # Safe compiler
use constant DUMMY_CLASS      => PARENT.'::Dummy';    # Dummy class
use constant MAX_FL           => 120;                 # Maximum file name length
use constant CACHE_EXT        => '.tts.cache';        # disk cache extension
use constant STAT_SIZE        => 7;                   # for stat()
use constant STAT_MTIME       => 9;                   # for stat()
use constant DELIMS           => qw( <% %> );         # default delimiter pair
use constant NEW_PERL         => $] >= 5.008;         # for I/O layer
use constant IS_FLOCK         => IS_WINDOWS ? ( Win32::IsWin95() ? 0 : 1 ) : 1;

use constant CHOMP_NONE       => 0x000000;
use constant COLLAPSE_NONE    => 0x000000;
use constant CHOMP_ALL        => 0x000002;
use constant CHOMP_LEFT       => 0x000004;
use constant CHOMP_RIGHT      => 0x000008;
use constant COLLAPSE_LEFT    => 0x000010;
use constant COLLAPSE_RIGHT   => 0x000020;
use constant COLLAPSE_ALL     => 0x000040;

use constant TAINT_CHECK_NORMAL  => 0x000000;
use constant TAINT_CHECK_ALL     => 0x000002;
use constant TAINT_CHECK_WINDOWS => 0x000004;
use constant TAINT_CHECK_FH_READ => 0x000008;

# first level directives
use constant DIR_CAPTURE      => '=';
use constant DIR_DYNAMIC      => '*';
use constant DIR_STATIC       => '+';
use constant DIR_NOTADELIM    => '!';
use constant DIR_COMMENT      => '#';
use constant DIR_COMMAND      => '|';
# second level directives
use constant DIR_CHOMP        => '-';
use constant DIR_COLLAPSE     => '~';
use constant DIR_CHOMP_NONE   => '^';

# token related indexes
use constant TOKEN_STR        =>  0;
use constant TOKEN_ID         =>  1;
use constant TOKEN_CHOMP      =>  2;
use constant TOKEN_TRIGGER    =>  3;

use constant TOKEN_CHOMP_NEXT =>  0; # sub-key for TOKEN_CHOMP
use constant TOKEN_CHOMP_PREV =>  1; # sub-key for TOKEN_CHOMP

use constant LAST_TOKEN       => -1;
use constant PREVIOUS_TOKEN   => -2;

use constant CACHE_FMODE      => 0600;

# SHA seems to be more accurate, so we'll try them first.
# Pure-Perl ones are slower, but they are fail-safes.
# However, Digest::SHA::PurePerl does not work under $perl < 5.6.
# But, Digest::Perl::MD5 seems to work under older perls (5.5.4 at least).
use constant DIGEST_MODS => qw(
   Digest::SHA
   Digest::SHA1
   Digest::SHA2
   Digest::SHA::PurePerl
   Digest::MD5
   MD5
   Digest::Perl::MD5
);

use constant RE_PIPE_SPLIT   => qr/ \| (?:\s+)? (PARAM|FILTER) : /xms;
use constant RE_FILTER_SPLIT => qr/ \, (?:\s+)? /xms;

use constant DISK_CACHE_MARKER => q{# This file is automatically generated by }
                               .  PARENT
                               ;

BEGIN {
   @ISA         = qw( Exporter );

   %EXPORT_TAGS = (
      info      =>   [qw(
                        IS_FLOCK
                        NEW_PERL
                        IS_WINDOWS
                        COMPILER
                        COMPILER_SAFE
                        DUMMY_CLASS
                        MAX_FL
                        CACHE_EXT
                        PARENT
                     )],
      templates =>   [qw(
                        DISK_CACHE_MARKER
                     )],
      delims    =>   [qw(
                        DELIM_START
                        DELIM_END
                        DELIMS
                     )],
      fields    =>   [qw(
                        DELIMITERS
                        AS_STRING
                        DELETE_WS
                        FAKER
                        FAKER_HASH
                        FAKER_SELF
                        FAKER_WARN
                        CACHE
                        CACHE_DIR
                        CACHE_OBJECT
                        MONOLITH
                        IO_OBJECT
                        STRICT
                        SAFE
                        HEADER
                        ADD_ARGS
                        WARN_IDS
                        CAPTURE_WARNINGS
                        TYPE
                        TYPE_FILE
                        COUNTER
                        COUNTER_INCLUDE
                        INSIDE_INCLUDE
                        NEEDS_OBJECT
                        CID
                        FILENAME
                        IOLAYER
                        STACK
                        USER_THANDLER
                        DEEP_RECURSION
                        INCLUDE_PATHS
                        PRE_CHOMP
                        POST_CHOMP
                        VERBOSE_ERRORS
                        TAINT_MODE
                        MAXOBJFIELD
                     )],
      chomp     =>   [qw(
                        CHOMP_NONE
                        COLLAPSE_NONE
                        CHOMP_ALL
                        CHOMP_LEFT
                        CHOMP_RIGHT
                        COLLAPSE_LEFT
                        COLLAPSE_RIGHT
                        COLLAPSE_ALL
                     )],
      directive =>   [qw(
                        DIR_CHOMP
                        DIR_COLLAPSE
                        DIR_CHOMP_NONE
                        DIR_CAPTURE
                        DIR_DYNAMIC
                        DIR_STATIC
                        DIR_NOTADELIM
                        DIR_COMMENT
                        DIR_COMMAND
                     )],
      token     =>   [qw(
                        TOKEN_ID
                        TOKEN_STR
                        TOKEN_CHOMP
                        TOKEN_TRIGGER
                        TOKEN_CHOMP_NEXT
                        TOKEN_CHOMP_PREV
                        LAST_TOKEN
                        PREVIOUS_TOKEN

                        T_DELIMSTART
                        T_DELIMEND
                        T_DISCARD
                        T_COMMENT
                        T_RAW
                        T_NOTADELIM
                        T_CODE
                        T_CAPTURE
                        T_DYNAMIC
                        T_STATIC
                        T_MAPKEY
                        T_COMMAND
                        T_MAXID
                      )],
      taint     =>   [qw(
                        TAINT_CHECK_NORMAL
                        TAINT_CHECK_ALL
                        TAINT_CHECK_WINDOWS
                        TAINT_CHECK_FH_READ
                     )],
      etc       =>   [qw(
                        DIGEST_MODS
                        STAT_MTIME
                        RE_DUMP_ERROR
                        RE_PIPE_SPLIT
                        RE_FILTER_SPLIT
                        RE_NONFILE
                        STAT_SIZE
                        MAX_RECURSION
                        CACHE_FMODE
                     )],
   );

   @EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   @EXPORT           = @EXPORT_OK;

}

BEGIN { require Exporter; }

package Text::Template::Simple::Util;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Text::Template::Simple::Constants qw( :info DIGEST_MODS );
use Carp qw( croak );

$VERSION = '0.79_03';

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
      'tts.io.slurp.taint'                       => "Can't untaint FH",
      'tts.io.hls.invalid'                       => 'FH is either absent or invalid',
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
      'tts.cache.populate.chmod'                 => 'Can not change file mode',
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

package Text::Template::Simple::Compiler::Safe;
# Safe compiler. Totally experimental
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Dummy;

$VERSION = '0.79_03';

sub _compile { shift; return __PACKAGE__->_object->reval(shift) }

sub _object {
   my $class = shift;
   if ( $class->can('object') ) {
      my $safe = $class->object;
      if ( $safe && ref($safe) ) {
         return $safe if eval { $safe->isa('Safe'); 'Safe-is-OK' };
      }
      my $end = $@ ? ': '.$@ : '.';
      warn "Safe object failed. Falling back to default" . $end;
   }
   require Safe;
   my $safe = Safe->new('Text::Template::Simple::Dummy');
   $safe->permit( $class->_permit );
   return $safe;
}

sub _permit {
   my $class = shift;
   return $class->permit if $class->can('permit');
   return qw( :default require caller );
}

package Text::Template::Simple::Cache::ID;
use strict;
use vars qw($VERSION);
use overload q{""} => 'get';
use Text::Template::Simple::Constants qw( MAX_FL );
use Text::Template::Simple::Util      qw( DIGEST fatal );

$VERSION = '0.79_03';

my $RE_INVALID = qr{[^A-Za-z_0-9]};

sub new {
   bless do { \my $anon }, shift;
}

sub get { my $self = shift; $$self }
sub set { my $self = shift; $$self = shift if defined $_[0]; return; }

sub generate { # cache id generator
   my $self   = shift;
   my $data   = shift or fatal('tts.cache.id.generate.data');
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
   my $data  = shift or fatal('tts.cache.id._custom.data');
   my $regex = shift || $RE_INVALID;
      $data  =~ s{$regex}{_}xmsg; # remove bogus characters
   my $len   = length( $data );
   if ( $len > MAX_FL ) { # limit file name length
      $data = substr $data, $len - MAX_FL, MAX_FL;
   }
   return $data;
}

package Text::Template::Simple::Base::Parser;
use strict;
use vars qw($VERSION);

$VERSION = '0.79_03';

use Text::Template::Simple::Util      qw(:all);
use Text::Template::Simple::Constants qw(:all);

my %INTERNAL = __PACKAGE__->_set_internal_templates;

sub _internal {
   my $self = shift;
   my $id   = shift            || fatal('tts.base.parser._internal.id');
   my $rv   = $INTERNAL{ $id } || fatal('tts.base.parser._internal.id');
   return $rv;
}

sub _parse {
   my $self     = shift;
   my $raw      = shift;
   my $map_keys = shift; # code sections are hash keys
   my $cache_id = shift;
   my $as_is    = shift; # i.e.: do not parse -> static include
   #$self->[NEEDS_OBJECT] = 0; # reset

   my($ds, $de) = @{ $self->[DELIMITERS] };
   my $faker    = $self->[INSIDE_INCLUDE] ? $self->_output_buffer_var
                                          : $self->[FAKER]
                                          ;
   my $buf_hash = $self->[FAKER_HASH];
   my $toke     = $self->connector('Tokenizer')->new(
                     $ds, $de, $self->[PRE_CHOMP], $self->[POST_CHOMP]
                  );
   my $code     = '';
   my $inside   = 0;

   my($mko, $mkc) = $self->_parse_mapkeys( $map_keys, $faker, $buf_hash );

   LOG( RAW => $raw ) if ( DEBUG() > 3 );

   my $uth = $self->[USER_THANDLER];

   my $h = {
      raw     => sub { ";$faker .= q~$_[0]~;" },
      capture => sub { ";$faker .= sub {" . $_[0] . "}->();"; },
      code    => sub { $_[0] . ';' },
   };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $as_is;

   # fetch and walk the tree
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $map_keys ) } ) {
      my($str, $id, $chomp, undef) = @{ $token };
      LOG( TOKEN => $toke->_visualize_tid($id) . " => $str" ) if DEBUG() > 1;
      next PARSER if T_DISCARD == $id;
      next PARSER if T_COMMENT == $id;

      if ( T_DELIMSTART == $id ) { $inside++; next PARSER; }
      if ( T_DELIMEND   == $id ) { $inside--; next PARSER; }

      if ( T_RAW == $id || T_NOTADELIM == $id ) {
         $code .= $h->{raw}->( $self->_chomp( $str, $chomp ) );
      }

      elsif ( T_CODE == $id ) {
         $code .= $h->{code}->($str);
      }

      elsif ( T_CAPTURE == $id ) {
         $code .= $h->{capture}->( $str );
      }

      elsif ( T_DYNAMIC == $id || T_STATIC == $id ) {
         $code .= $h->{capture}->( $self->_needs_object->_include($id, $str) );
      }

      elsif ( T_MAPKEY == $id ) {
         $code .= sprintf $mko, $mkc ? ( ($str) x 5 ) : $str;
      }

      elsif ( T_COMMAND == $id ) {
         $code .= $h->{raw}->( $self->_parse_command( $str ) );
      }

      else {
         LOG(
            $uth  ? (USER_THANDLER => "$id")
                  : (UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)")
         ) if DEBUG;
         $code .= $uth ? $uth->( $self, $id ,$str, $h ) : $h->{raw}->( $str );
      }

   }

   $self->[FILENAME] ||= '<ANON>';

   fatal(
      'tts.base.parser._parse.unbalanced',
         abs($inside),
         ($inside > 0 ? 'opening' : 'closing'),
         $self->[FILENAME]
   ) if $inside;

   return $self->_wrapper( $code, $cache_id, $faker, $map_keys, $h );
}

sub _parse_command {
   my $self = shift;
   my $str  = shift;
   my($head, $raw_block) = split /;/, $str, 2;
   my @buf  = split RE_PIPE_SPLIT, '|' . trim($head);
   shift(@buf);
   my %com  = map { trim $_ } @buf;

   if ( $com{FILTER} ) {
      # embed into the template & NEEDS_OBJECT++ ???
      local $self->[FILENAME] = '<ANON BLOCK>';
      $self->_call_filters( \$raw_block, split RE_FILTER_SPLIT, $com{FILTER} );
   }

   return $raw_block;
}

sub _chomp {
   # remove the unnecessary white space
   my $self = shift;
   my($str, $chomp) = @_;

   # NEXT: discard: left;  right -> left
   # PREV: discard: right; left  -> right
   my($next, $prev) = @{ $chomp };
   $next ||= CHOMP_NONE;
   $prev ||= CHOMP_NONE;

   my $left_collapse  = ( $next & COLLAPSE_ALL ) || ( $next & COLLAPSE_RIGHT);
   my $left_chomp     = ( $next & CHOMP_ALL    ) || ( $next & CHOMP_RIGHT   );

   my $right_collapse = ( $prev & COLLAPSE_ALL ) || ( $prev & COLLAPSE_LEFT );
   my $right_chomp    = ( $prev & CHOMP_ALL    ) || ( $prev & CHOMP_LEFT    );

   $str = $left_collapse  ? ltrim($str, ' ')
        : $left_chomp     ? ltrim($str)
        :                   $str
        ;

   $str = $right_collapse ? rtrim($str, ' ')
        : $right_chomp    ? rtrim($str)
        :                   $str
        ;

   return $str;
}

sub _wrapper {
   # this'll be tricky to re-implement around a template
   my $self     = shift;
   my $code     = shift;
   my $cache_id = shift;
   my $faker    = shift;
   my $map_keys = shift;
   my $h        = shift;
   my $buf_hash = $self->[FAKER_HASH];

   my $wrapper    = '';
   my $inside_inc = $self->[INSIDE_INCLUDE] != -1 ? 1 : 0;

   # build the anonymous sub
   if ( ! $inside_inc ) {
      # don't duplicate these if we're including something
      $wrapper .= "package " . DUMMY_CLASS . ";";
      $wrapper .= 'use strict;' if $self->[STRICT];
   }
   $wrapper .= 'sub { ';
   $wrapper .= sprintf q~local $0 = '%s';~, escape( q{'} => $self->[FILENAME] );
   if ( $self->[NEEDS_OBJECT] ) {
      --$self->[NEEDS_OBJECT];
      $wrapper .= 'my ' . $self->[FAKER_SELF] . ' = shift;';
   }
   $wrapper .= $self->[HEADER].';'             if $self->[HEADER];
   $wrapper .= "my $faker = '';";
   $wrapper .= $self->_add_stack( $cache_id )  if $self->[STACK];
   $wrapper .= "my $buf_hash = {\@_};"         if $map_keys;
   $wrapper .= $self->_add_sigwarn if $self->[CAPTURE_WARNINGS];
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . ";";
   $wrapper .= $self->_dump_sigwarn($h) if $self->[CAPTURE_WARNINGS];
   $wrapper .= "return $faker;";
   $wrapper .= '}';
   # make this a capture sub if we're including
   $wrapper .= '->()' if $inside_inc;

   LOG( COMPILED =>  $self->_mini_compiler(
                        $self->_internal('fragment'),
                        { FRAGMENT => $self->_tidy($wrapper) }
                     )
   ) if DEBUG > 1;
   #LOG( OUTPUT => $wrapper );
   # reset
   $self->[DEEP_RECURSION] = 0 if $self->[DEEP_RECURSION];
   return $wrapper;
}

sub _parse_mapkeys {
   my($self, $map_keys, $faker, $buf_hash) = @_;
   return undef, undef if ! $map_keys;

   my $mkc = $map_keys eq 'check';
   my $mki = $map_keys eq 'init';
   my $t   = $mki ? 'map_keys_init'
           : $mkc ? 'map_keys_check'
           :        'map_keys_default'
           ;
   my $mko = $self->_mini_compiler(
               $self->_internal( $t ) => {
                  BUF  => $faker,
                  HASH => $buf_hash,
                  KEY  => '%s',
               } => {
                  flatten => 1,
               }
            );
   return $mko, $mkc;
}

sub _add_sigwarn {
   my $self = shift;
   $self->[FAKER_WARN] = $self->_output_buffer_var('array');
   my $rv = $self->_mini_compiler(
               $self->_internal('add_sigwarn'),
               { BUF     => $self->[FAKER_WARN] },
               { flatten => 1                   }
            );
   return $rv;
}

sub _dump_sigwarn {
   my $self = shift;
   my $h    = shift;
   my $rv = $h->{capture}->(
               $self->_mini_compiler(
                  $self->_internal('dump_sigwarn'),
                  { BUF     => $self->[FAKER_WARN] },
                  { flatten => 1                   }
               )
            );
   return $rv;
}

sub _add_stack {
   my $self    = shift;
   my $cs_name = shift || '<ANON TEMPLATE>';
   my $stack   = $self->[STACK] || '';

   return if lc($stack) eq 'off';

   my $check   = ($stack eq '1' || $stack eq 'yes' || $stack eq 'on')
               ? 'string'
               : $stack
               ;

   my($type, $channel) = split /:/, $check;
   $channel = ! $channel             ? 'warn'
            :   $channel eq 'buffer' ? $self->[FAKER] . ' .= '
            :                          'warn'
            ;

   foreach my $e ( $cs_name, $type, $channel ) {
      $e =~ s{'}{\\'}xmsg;
   }

   return "$channel stack( { type => '$type', name => '$cs_name' } );";
}

sub _set_internal_templates {
   # we need string eval in this template to catch syntax errors
   sub_include => q~
      <%OBJECT%>->_compile(
         do {
            local $@;
            my $file = eval '<%INCLUDE%>';
            my $rv;
            if ( my $e = $@ ) {
               chomp $e;
               $file ||= '<%INCLUDE%>';
               my $m = "The parameter ($file) is not a file. "
                     . "Error from sub-include ($file): $e";
               $rv = [ ERROR => '<%ERROR_TITLE%> ' . $m ]
            }
            else {
               $rv = $file;
            }
            $rv;
         },
         <%PARAMS%>,
         {
            _sub_inc => '<%TYPE%>',
            _filter  => '<%FILTER%>',
         }
      )
   ~,
   no_monolith => q*
      <%OBJECT%>->compile(
         q~<%FILE%>~,
         undef,
         {
            chkmt    => 1,
            _sub_inc => q~<%TYPE%>~,
         }
      );
   *,

   # see _parse()
   map_keys_check => q(
      <%BUF%> .= exists <%HASH%>->{"<%KEY%>"}
               ? (
                  defined <%HASH%>->{"<%KEY%>"}
                  ? <%HASH%>->{"<%KEY%>"}
                  : "[ERROR] Key not defined: <%KEY%>"
                  )
               : "[ERROR] Invalid key: <%KEY%>"
               ;
   ),

   map_keys_init => q(
      <%BUF%> .= <%HASH%>->{"<%KEY%>"} || '';
   ),
   map_keys_default => q(
      <%BUF%> .= <%HASH%>->{"<%KEY%>"};
   ),

   add_sigwarn => q(
      my <%BUF%>;
      local $SIG{__WARN__} = sub {
         push @{ <%BUF%> }, $_[0];
      };
   ),
   dump_sigwarn => q(
      join("\n",
            map {
               s{ \A \s+    }{}xms;
               s{    \s+ \z }{}xms;
               "[warning] $_\n"
            } @{ <%BUF%> }
         );
   ),

   compile_error => <<'TEMPLATE_CONSTANT',
Error compiling code fragment (cache id: <%CID%>):

<%ERROR%>
-------------------------------
PARSED CODE (VERBATIM):
-------------------------------

<%PARSED%>

-------------------------------
PARSED CODE    (tidied):
-------------------------------

<%TIDIED%>
TEMPLATE_CONSTANT

   fragment => <<'TEMPLATE_CONSTANT',

# BEGIN TIDIED FRAGMENT

<%FRAGMENT%>

# END TIDIED FRAGMENT
TEMPLATE_CONSTANT

   disk_cache_comment => <<"TEMPLATE_CONSTANT",
# !!!   W A R N I N G      W A R N I N G      W A R N I N G   !!!
# This file was automatically generated by <%NAME%> on <%DATE%>.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
TEMPLATE_CONSTANT
}

package Text::Template::Simple::Base::Include;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.79_03';

sub _include_no_monolith {
   # no monolith eh?
   my $self = shift;
   my $type = shift;
   my $file = shift;
   my $rv   =  $self->_mini_compiler(
                  $self->_internal('no_monolith') => {
                     OBJECT => $self->[FAKER_SELF],
                     FILE   => escape('~' => $file),
                     TYPE   => escape('~' => $type),
                  } => {
                     flatten => 1,
                  }
               );
   ++$self->[NEEDS_OBJECT];
   return $rv;
}

sub _include_static {
   my($self, $file, $text, $err) = @_;
   return $self->[MONOLITH]
        ? 'q~' . escape('~' => $text) . '~;'
        : $self->_include_no_monolith( T_STATIC, $file )
        ;
}

sub _include_dynamic {
   my($self, $file, $text, $err) = @_;
   my $rv   = '';

   ++$self->[INSIDE_INCLUDE];
   $self->[COUNTER_INCLUDE] ||= {};

   # ++$self->[COUNTER_INCLUDE]{ $file } if $self->[TYPE_FILE] eq $file;

   if ( ++$self->[COUNTER_INCLUDE]{ $file } >= MAX_RECURSION ) {
      # failsafe
      my $max   = MAX_RECURSION;
      my $error = qq{$err Deep recursion (>=$max) detected in }
                . qq{the included file: $file};
      LOG( DEEP_RECURSION => $file ) if DEBUG();
      $error = escape( '~' => $error );
      $self->[DEEP_RECURSION] = 1;
      $rv .= "q~$error~";
   }
   else {
      # local stuff is for file name access through $0 in templates
      $rv .= $self->[MONOLITH]
           ? do { local $self->[FILENAME] = $file; $self->_parse( $text ) }
           : $self->_include_no_monolith( T_DYNAMIC, $file )
           ;
   }

   --$self->[INSIDE_INCLUDE]; # critical: always adjust this
   return $rv;
}


sub _include {
   my $self       = shift;
   my $type       = shift || 0;
   my $file       = shift;
   my $is_static  = T_STATIC  == $type ? 1 : 0;
   my $is_dynamic = T_DYNAMIC == $type ? 1 : 0;
   my $known      = $is_static || $is_dynamic;

   fatal('tts.base.include._include.unknown', $type) if not $known;

   $file = trim $file;

   my $err    = $self->_include_error( $type );
   my $exists = $self->io->file_exists( $file );
   my $interpolate;

   if ( $exists ) {
      $file        = $exists; # file path correction
      $interpolate = 0;
   }
   else {
      $interpolate = 1; # just guessing ...
   }

   return "q~$err '" . escape('~' => $file) . "' is a directory~"
      if $self->io->is_dir( $file );

   if ( DEBUG() ) {
      require Text::Template::Simple::Tokenizer;
      my $toke =  Text::Template::Simple::Tokenizer->new(
                     @{ $self->[DELIMITERS] },
                     $self->[PRE_CHOMP],
                     $self->[POST_CHOMP]
                  );
      LOG( INCLUDE => $toke->_visualize_tid($type) . " => '$file'" );
   }

   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG();
      return $rv;
   }

   my $text;
   eval { $text = $self->io->slurp($file); };
   return "q~$err $@~" if $@;

   my $meth = '_include_' . ($is_dynamic ? 'dynamic' : 'static');
   return $self->$meth( $file, $text, $err);
}

sub _interpolate {
   my $self   = shift;
   my $file   = shift;
   my $type   = shift;
   my $etitle = $self->_include_error($type);

   # so that, you can pass parameters, apply filters etc.
   my %inc = (INCLUDE => map { trim $_ } split RE_PIPE_SPLIT, $file );

   if ( $self->io->file_exists( $inc{INCLUDE} ) ) {
      # well... constantly working around :p
      $inc{INCLUDE} = qq{'$inc{INCLUDE}'};
   }

   # die "You can not pass parameters to static includes"
   #    if $inc{PARAM} && T_STATIC  == $type;

   my $filter = $inc{FILTER} ? escape( q{'} => $inc{FILTER} ) : '';

   my $rv = $self->_mini_compiler(
               $self->_internal('sub_include') => {
                  OBJECT      => $self->[FAKER_SELF],
                  INCLUDE     => escape( q{'} => $inc{INCLUDE} ),
                  ERROR_TITLE => escape( q{'} => $etitle ),
                  TYPE        => $type,
                  PARAMS      => $inc{PARAM} ? qq{[$inc{PARAM}]} : 'undef',
                  FILTER      => $filter,
               } => {
                  flatten => 1,
               }
            );
   return $rv;
}

sub _include_error {
   my $self  = shift;
   my $type  = shift;
   my $val   = T_DYNAMIC == $type ? 'dynamic'
             : T_STATIC  == $type ? 'static'
             :                      'unknown'
             ;
   my $title = '[ ' . $val . ' include error ]';
   return $title;
}

package Text::Template::Simple::Base::Examine;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.79_03';

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
      if ( my $path = $self->io->file_exists( $thing ) ) {
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

package Text::Template::Simple::Base::Compiler;
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

$VERSION = '0.79_03';

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
      if ( $self->[TYPE] eq 'FILE' ) {
         $opt->{chkmt} = (stat $tmpx)[STAT_MTIME];
      }
      else {
         LOG( DISABLE_MT => "Disabling chkmt. Template is not a file" )
            if DEBUG();
         $opt->{chkmt} = 0;
      }
   }

   LOG( COMPILE => $opt->{id} ) if defined $opt->{id} && DEBUG();

   my($CODE, $ok);
   my $cache_id = '';

   my $as_is = $opt->{_sub_inc} && $opt->{_sub_inc} == T_STATIC;

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

   if ( not $ok ) {
      # we have a cache miss; parse and compile
      LOG( CACHE_MISS => $cache_id ) if DEBUG();
      my $parsed = $self->_parse( $tmp, $opt->{map_keys}, $cache_id, $as_is  );
      $CODE      = $self->cache->populate( $cache_id, $parsed, $opt->{chkmt} );
   }

   my   @args;
   push @args, $self if $self->[NEEDS_OBJECT];
   push @args, @{ $self->[ADD_ARGS] } if $self->[ADD_ARGS];
   push @args, @{ $param };
   my $out = $CODE->( @args );

   if ( $opt->{_filter} ) {
      $self->_call_filters( \$out, split RE_FILTER_SPLIT, $opt->{_filter} );
   }

   return $out;
}

sub _call_filters {
   my $self    = shift;
   my $oref    = shift;
   my @filters = @_;
   my $fname   = $self->[FILENAME];
   my $fbase   = 'Text::Template::Simple::Dummy';

   APPLY_FILTERS: foreach my $filter ( @filters ) {
      my $fref = $fbase->can( "filter_" . $filter );
      if ( ! $fref ) {
         $$oref .= "\n[ filter warning ] Can not apply undefined filter $filter to $fname\n";
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

package Text::Template::Simple::Tokenizer;
use strict;
use vars qw($VERSION);

$VERSION = '0.79_03';

use constant CMD_CHAR             =>  0;
use constant CMD_ID               =>  1;
use constant CMD_CB               =>  2; # callbacks
use constant ID_DS                =>  0;
use constant ID_DE                =>  1;
use constant ID_PRE_CHOMP         =>  2;
use constant ID_POST_CHOMP        =>  3;
use constant SUBSTR_OFFSET_FIRST  =>  0;
use constant SUBSTR_OFFSET_SECOND =>  1;
use constant SUBSTR_LENGTH        =>  1;
use Text::Template::Simple::Util      qw( LOG fatal );
use Text::Template::Simple::Constants qw( :chomp :directive :token );

my @COMMANDS = ( # default command list
   # cmd            id
   [ DIR_CAPTURE  , T_CAPTURE   ],
   [ DIR_DYNAMIC  , T_DYNAMIC,  ],
   [ DIR_STATIC   , T_STATIC,   ],
   [ DIR_NOTADELIM, T_NOTADELIM ],
   [ DIR_COMMENT  , T_COMMENT   ],
   [ DIR_COMMAND  , T_COMMAND   ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS]         = shift || fatal('tts.tokenizer.new.ds');
   $self->[ID_DE]         = shift || fatal('tts.tokenizer.new.de');
   $self->[ID_PRE_CHOMP]  = shift || CHOMP_NONE;
   $self->[ID_POST_CHOMP] = shift || CHOMP_NONE;
   $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my $self       = shift;
   my $tmp        = shift || fatal('tts.tokenizer.tokenize.tmp');
   my $map_keys   = shift;
   my($ds, $de)   = ($self->[ID_DS], $self->[ID_DE]);
   my($qds, $qde) = map { quotemeta $_ } $ds, $de;

   my(@tokens, $inside);

   OUT_TOKEN: foreach my $i ( split /($qds)/, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ $i, T_DELIMSTART, [], undef ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach my $j ( split /($qde)/, $i ) {
         if ( $j eq $de ) {
            my $last = $tokens[LAST_TOKEN];
            if ( T_NOTADELIM == $last->[TOKEN_ID] ) {
               $last->[TOKEN_STR] = $self->tilde( $last->[TOKEN_STR] . $de );
            }
            else {
               push @tokens, [ $j, T_DELIMEND, [], undef ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   $self->_debug_tokens( \@tokens ) if $self->can('DEBUG_TOKENS');

   return \@tokens;
}

sub tilde { shift; Text::Template::Simple::Util::escape( '~' => @_ ) }
sub quote { shift; Text::Template::Simple::Util::escape( '"' => @_ ) }

sub _debug_tokens {
   my $self   = shift;
   my $tokens = shift;
   # TODO: heredocs look ugly
   my $buf = <<'HEAD';

---------------------------
       TOKEN DUMP
---------------------------
HEAD

   my $tmp = <<'DUMP';
ID        : %s
STRING    : %s
CHOMP_NEXT: %s
CHOMP_PREV: %s
TRIGGER   : %s
---------------------------
DUMP

   foreach my $t ( @{ $tokens } ) {
      my $s = $t->[TOKEN_STR];
      $s =~ s{\r}{\\r}xmsg;
      $s =~ s{\n}{\\n}xmsg;
      $s =~ s{\f}{\\f}xmsg;
      $s =~ s{\s}{\\s}xmsg;
      my @v = (
         scalar $self->_visualize_chomp( $t->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT] ),
         scalar $self->_visualize_chomp( $t->[TOKEN_CHOMP][TOKEN_CHOMP_PREV] ),
         scalar $self->_visualize_chomp( $t->[TOKEN_TRIGGER]                 )
      );
      @v = map { $_ eq 'undef' ? '' : $_ } @v;
      $buf .= sprintf $tmp, $self->_visualize_tid( $t->[TOKEN_ID] ), $s, @v;
   }
   Text::Template::Simple::Util::LOG( DEBUG => $buf );
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub _token_for_command {
   my($self, $tree, $map_keys, $str, $last, $second, $cmd, $inside) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $second, $last );
   my $len  = length($str);
   my $cb   = $map_keys ? 'quote' : $cmd->[CMD_CB];
   my $soff = $copen ? 2 : 1;
   my $slen = $len - ($cclose ? $soff+1 : 1);
   my $buf  = substr $str, $soff, $slen;

   if ( T_NOTADELIM == $cmd->[CMD_ID] ) {
      $buf = $self->[ID_DS] . $buf;
      $tree->[LAST_TOKEN][TOKEN_ID] = T_DISCARD;
   }

   my $needs_chomp = defined($ctoken);
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   my $id  = $map_keys ? T_RAW              : $cmd->[CMD_ID];
   my $val = $cb       ? $self->$cb( $buf ) : $buf;

   return [
            $val,
            $id,
            [CHOMP_NONE, CHOMP_NONE],
            $needs_chomp ? $ctoken : undef # trigger
          ];
}

sub _token_for_code {
   my($self, $tree, $map_keys, $str, $last, $first) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $first, $last );
   my $len  = length($str);
   my $soff = $copen ? 1 : 0;
   my $slen = $len - ( $cclose ? $soff+1 : 0 );

   my $needs_chomp = defined($ctoken);
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   return   [
               substr($str, $soff, $slen),
               $map_keys ? T_MAPKEY : T_CODE,
               [ CHOMP_NONE, CHOMP_NONE ],
               $needs_chomp ? $ctoken : undef # trigger
            ];
}

sub _get_command_chars {
   my($self, $str) = @_;
   my($first, $second, $last) = ('') x 3;
   # $first is the left-cmd, $last is the right-cmd. $second is the extra
   $first  = substr $str, SUBSTR_OFFSET_FIRST , SUBSTR_LENGTH if $str ne '';
   $second = substr $str, SUBSTR_OFFSET_SECOND, SUBSTR_LENGTH if $str ne '';
   $last   = substr $str, length($str) - 1    , SUBSTR_LENGTH if $str ne '';
   return $first, $second, $last;
}

sub _token_code {
   my($self, $str, $inside, $map_keys, $tree) = @_;
   my($first, $second, $last) = $self->_get_command_chars( $str );

   if ( $inside ) {
      my @common = ($tree, $map_keys, $str, $last);
      foreach my $cmd ( @COMMANDS, $self->_user_commands ) {
         next if $first ne $cmd->[CMD_CHAR];
         return $self->_token_for_command( @common, $second, $cmd, $inside );
      }
      return $self->_token_for_code( @common, $first );
   }

   my $prev = $tree->[PREVIOUS_TOKEN];

   return [
            $self->tilde( $str ),
            T_RAW,
            [ $prev ? $prev->[TOKEN_TRIGGER] : undef, CHOMP_NONE ],
            undef # trigger
         ];
}

sub _chomp_token {
   my($self, $open, $close) = @_;
   my($pre, $post) = ( $self->[ID_PRE_CHOMP], $self->[ID_POST_CHOMP] );
   my $c      = CHOMP_NONE;

   my $copen  = $open  eq DIR_CHOMP_NONE ? -1
              : $open  eq DIR_COLLAPSE   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre   &  COLLAPSE_ALL   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre   &  CHOMP_ALL      ? do { $c |=     CHOMP_LEFT; 1 }
              : $open  eq DIR_CHOMP      ? do { $c |=     CHOMP_LEFT; 1 }
              :                            0
              ;

   my $cclose = $close eq DIR_CHOMP_NONE ? -1
              : $close eq DIR_COLLAPSE   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post  &  COLLAPSE_ALL   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post  &  CHOMP_ALL      ? do { $c |=    CHOMP_RIGHT; 1 }
              : $close eq DIR_CHOMP      ? do { $c |=    CHOMP_RIGHT; 1 }
              :                            0
              ;

   my $cboth  = $copen > 0 && $cclose > 0;

   $c |= COLLAPSE_ALL if( ($c & COLLAPSE_LEFT) && ($c & COLLAPSE_RIGHT) );
   $c |= CHOMP_ALL    if( ($c & CHOMP_LEFT   ) && ($c & CHOMP_RIGHT   ) );

   return $copen, $cclose, $c || CHOMP_NONE;
}

sub _chomp_prev {
   my($self, $tree, $ctoken) = @_;
   my $prev = $tree->[PREVIOUS_TOKEN] || return; # no previous if this is first
   return if T_RAW != $prev->[TOKEN_ID]; # only RAWs can be chomped

   my $tc_prev = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_PREV];
   my $tc_next = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT];

   $prev->[TOKEN_CHOMP] = [
                           $tc_next ? $tc_next           : CHOMP_NONE,
                           $tc_prev ? $tc_prev | $ctoken : $ctoken
                           ];
   return;
}

sub _visualize_chomp {
   my $self  = shift;
   my $param = shift;
   if ( ! defined $param ) {
      return wantarray ? ("undef", "undef") : "undef";
   }

   my @types = (
      [ COLLAPSE_ALL   => COLLAPSE_ALL   ],
      [ COLLAPSE_LEFT  => COLLAPSE_LEFT  ],
      [ COLLAPSE_RIGHT => COLLAPSE_RIGHT ],
      [ CHOMP_ALL      => CHOMP_ALL      ],
      [ CHOMP_LEFT     => CHOMP_LEFT     ],
      [ CHOMP_RIGHT    => CHOMP_RIGHT    ],
      [ CHOMP_NONE     => CHOMP_NONE     ],
      [ COLLAPSE_NONE  => COLLAPSE_NONE  ],
   );

   my $which;
   foreach my $type ( @types ) {
       if ( $type->[1] & $param ) {
           $which = $type->[0];
           last;
       }
   }

   $which ||= "undef";
   return $which if ! wantarray;

   # can be smaller?
   my @test = (
      sprintf( "COLLAPSE_ALL  : %s", $param & COLLAPSE_ALL   ? 1 : 0 ),
      sprintf( "COLLAPSE_LEFT : %s", $param & COLLAPSE_LEFT  ? 1 : 0 ),
      sprintf( "COLLAPSE_RIGHT: %s", $param & COLLAPSE_RIGHT ? 1 : 0 ),
      sprintf( "CHOMP_ALL     : %s", $param & CHOMP_ALL      ? 1 : 0 ),
      sprintf( "CHOMP_LEFT    : %s", $param & CHOMP_LEFT     ? 1 : 0 ),
      sprintf( "CHOMP_RIGHT   : %s", $param & CHOMP_RIGHT    ? 1 : 0 ),
      sprintf( "COLLAPSE_NONE : %s", $param & COLLAPSE_NONE  ? 1 : 0 ),
      sprintf( "CHOMP_NONE    : %s", $param & CHOMP_NONE     ? 1 : 0 ),
   );

   return $which, join( "\n", @test );
}

sub _visualize_tid {
   my $self = shift;
   my $id   = shift;
   my @ids  = ( undef,
                qw(
                     T_DELIMSTART
                     T_DELIMEND
                     T_DISCARD
                     T_COMMENT
                     T_RAW
                     T_NOTADELIM
                     T_CODE
                     T_CAPTURE
                     T_DYNAMIC
                     T_STATIC
                     T_MAPKEY
                     T_COMMAND
                  )
               );
   my $rv = $ids[$id] || ( defined $id ? $id : 'undef' );
   return $rv;
}

package Text::Template::Simple::IO;
use strict;
use vars qw($VERSION);
use File::Spec;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util qw( DEBUG LOG ishref binary_mode fatal );
use constant MY_IO_LAYER      => 0;
use constant MY_INCLUDE_PATHS => 1;
use constant MY_TAINT_MODE    => 2;

$VERSION = '0.79_03';

sub new {
   my $class = shift;
   my $layer = shift;
   my $paths = shift;
   my $tmode = shift;
   my $self  = [ undef, undef, undef ];
   bless $self, $class;
   $self->[MY_IO_LAYER]      = $layer if defined $layer;
   $self->[MY_INCLUDE_PATHS] = [ @{ $paths } ] if $paths; # copy
   $self->[MY_TAINT_MODE]    = $tmode;
   $self;
}

sub validate {
   my $self = shift;
   my $type = shift || fatal('tts.io.validate.type');
   my $path = shift || fatal('tts.io.validate.path');

   if ( $type eq 'dir' ) {
      require File::Spec;
      $path = File::Spec->canonpath( $path );
      my $wdir;

      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $path );
         if( Win32::GetLastError() ) {
            LOG( FAIL => "Win32::GetFullPathName( $path ): $^E" ) if DEBUG();
            $wdir = ''; # die "Win32::GetFullPathName: $^E";
         }
         else {
            my $ok = -e $wdir && -d _;
            $wdir  = '' if not $ok;
         }
      }

      $path = $wdir if $wdir;
      my $ok = -e $path && -d _;
      return if not $ok;
      return $path;
   }

   fatal('tts.io.validate.file');
}

sub layer {
   return if ! NEW_PERL;
   my $self   = shift;
   my $fh     = shift || fatal('tts.io.layer.fh');
   my $layer  = $self->[MY_IO_LAYER];
   binary_mode( $fh, $layer ) if $layer;
   return;
}

sub slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my($fh, $seek);
   LOG(IO_SLURP => $file) if DEBUG();

   if ( fileno $file ) {
      $fh   = $file;
      $seek = 1;
   }
   else {
      $fh = IO::File->new;
      $fh->open($file, 'r') or fatal('tts.io.slurp.open', $file, $!);
   }

   flock $fh,    Fcntl::LOCK_SH()  if IS_FLOCK;
   seek  $fh, 0, Fcntl::SEEK_SET() if IS_FLOCK && $seek;
   $self->layer( $fh ) if ! $seek; # apply the layer only if we opened this

   if ( $self->_handle_looks_safe( $fh ) ) {
      require IO::Handle;
      my $rv = IO::Handle::untaint( $fh );
      fatal('tts.io.slurp.taint') if $rv != 0;
   }

   my $tmp = do { local $/; my $rv = <$fh>; $rv };
   flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
   close $fh if ! $seek; # close only if we opened this
   return $tmp;
}

sub _handle_looks_safe {
   # Cargo Culting: original code was taken from "The Camel"
   my $self = shift;
   my $fh   = shift;
   fatal('tts.io.hls.invalid') if ! $fh || ! fileno $fh;

   require File::stat;
   my $i = File::stat::stat( $fh );
   return if ! $i;

   my $tmode = $self->[MY_TAINT_MODE];

   # owner neither superuser nor "me", whose
   # real uid is in the $< variable
   return if $i->uid != 0 && $i->uid != $<;

   # Check whether group or other can write file.
   # Read check is disabled by default
   # Mode always 0666 on Windows, so all tests below are disabled on Windows
   # unless you force them to run
   LOG( FILE_MODE => sprintf "%04o", $i->mode & 07777) if DEBUG;

   my $bypass   = IS_WINDOWS && ! ( $tmode & TAINT_CHECK_WINDOWS ) ? 1 : 0;
   my $go_write = $bypass ? 0 : $i->mode & 022;
   my $go_read  = ! $bypass && ( $tmode & TAINT_CHECK_FH_READ )
                ? $i->mode & 066
                : 0;

   LOG( TAINT => "tmode:$tmode; bypass:$bypass; "
                ."go_write:$go_write; go_read:$go_read") if DEBUG;

   return if $go_write || $go_read;
   return 1;
}

sub is_file {
   # safer than a simple "-e"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && ! -d $file;
}

sub is_dir {
   # safer than a simple "-d"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && -d $file;
}

sub file_exists {
   my $self = shift;
   my $file = shift;

   return $file if $self->is_file( $file );

   foreach my $path ( @{ $self->[MY_INCLUDE_PATHS] } ) {
      my $test = File::Spec->catfile( $path, $file );
      return $test if $self->is_file( $test );
   }

   return; # fail!
}

sub _looks_like_file {
   my $self = shift;
   my $file = shift || return;
   return     ref $file               ? 0
         :        $file =~ RE_NONFILE ? 0
         : length $file >= 255        ? 0
         :     -e $file               ? 1
         :                              0
         ;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG();
   return;
}

package Text::Template::Simple::Dummy;
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Caller;
use Text::Template::Simple::Util qw();

$VERSION = '0.79_03';

sub stack { # just a wrapper
   my $opt = shift || {};
   Text::Template::Simple::Util::fatal('tts.caller.stack.hash')
      if ! Text::Template::Simple::Util::ishref($opt);
   $opt->{frame} = 1;
   Text::Template::Simple::Caller->stack( $opt );
}

package Text::Template::Simple::Compiler;
# the "normal" compiler
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Dummy;

$VERSION = '0.79_03';

sub _compile { shift; return eval shift }

package Text::Template::Simple::Caller;
use strict;
use vars qw($VERSION);
use constant PACKAGE    => 0;
use constant FILENAME   => 1;
use constant LINE       => 2;
use constant SUBROUTINE => 3;
use constant HASARGS    => 4;
use constant WANTARRAY  => 5;
use constant EVALTEXT   => 6;
use constant IS_REQUIRE => 7;
use constant HINTS      => 8;
use constant BITMASK    => 9;
use Text::Template::Simple::Util qw( ishref fatal );

$VERSION = '0.79_03';

sub stack {
   my $self    = shift;
   my $opt     = shift || {};
   fatal('tts.caller.stack.hash') if ! ishref($opt);
   my $frame   = $opt->{frame} || 0;
   my $type    = $opt->{type}  || '';
   my(@callers, $context);

   TRACE: while ( my @c = caller ++$frame ) {

      INITIALIZE: foreach my $id ( 0 .. $#c ) {
         next INITIALIZE if $id == WANTARRAY; # can be undef
         $c[$id] ||= '';
      }

      $context = defined $c[WANTARRAY] ?  ( $c[WANTARRAY] ? 'LIST' : 'SCALAR' )
               :                            'VOID'
               ;

      push  @callers,
            {
               class    => $c[PACKAGE   ],
               file     => $c[FILENAME  ],
               line     => $c[LINE      ],
               sub      => $c[SUBROUTINE],
               context  => $context,
               isreq    => $c[IS_REQUIRE],
               hasargs  => $c[HASARGS   ] ? 'YES' : 'NO',
               evaltext => $c[EVALTEXT  ],
               hints    => $c[HINTS     ],
               bitmask  => $c[BITMASK   ],
            };

   }

   return if ! @callers; # no one called us?
   return reverse @callers if ! $type;

   if ( $self->can( my $method = '_' . $type ) ) {
      return $self->$method( $opt, \@callers );
   }

   fatal('tts.caller.stack.type', $type);
}

sub _string {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $is_html = shift;

   my $name = $opt->{name} ? "FOR $opt->{name} " : "";
   my $rv   = qq{[ DUMPING CALLER STACK $name]\n\n};

   foreach my $c ( reverse @{$callers} ) {
      $rv .= sprintf qq{%s %s() at %s line %s\n},
                     $c->{context},
                     $c->{sub},
                     $c->{file},
                     $c->{line};
   }

   $rv = "<!-- $rv -->" if $is_html;
   return $rv;
}

sub _html_comment {
   shift->_string( @_, 'add html comment' );
}

sub _html_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $rv      = q{
   <div id="ttsc-wrapper">
   <table border="1" cellpadding="1" cellspacing="2" id="ttsc-dump">
      <tr>
         <td class="ttsc-title">CONTEXT</td>
         <td class="ttsc-title">SUB</td>
         <td class="ttsc-title">LINE</td>
         <td class="ttsc-title">FILE</td>
         <td class="ttsc-title">HASARGS</td>
         <td class="ttsc-title">IS_REQUIRE</td>
         <td class="ttsc-title">EVALTEXT</td>
         <td class="ttsc-title">HINTS</td>
         <td class="ttsc-title">BITMASK</td>
      </tr>
   };

   foreach my $c ( reverse @{$callers} ) {
      $self->_html_table_blank_check( $c ); # modifies  in place
      $rv .= qq{
      <tr>
         <td class="ttsc-value">$c->{context}</td>
         <td class="ttsc-value">$c->{sub}</td>
         <td class="ttsc-value">$c->{line}</td>
         <td class="ttsc-value">$c->{file}</td>
         <td class="ttsc-value">$c->{hasargs}</td>
         <td class="ttsc-value">$c->{isreq}</td>
         <td class="ttsc-value">$c->{evaltext}</td>
         <td class="ttsc-value">$c->{hints}</td>
         <td class="ttsc-value">$c->{bitmask}</td>
      </tr>
      };
   }

   return $rv . q{</table></div>};
}

sub _html_table_blank_check {
   my $self   = shift;
   my $struct = shift;
   foreach my $id ( keys %{ $struct }) {
      if ( not defined $struct->{ $id } or $struct->{ $id } eq '' ) {
         $struct->{ $id } = '&#160;';
      }
   }
}

sub _text_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   eval { require Text::Table; };
   fatal('tts.caller._text_table.module', $@) if $@;

   my $table = Text::Table->new( qw(
                  | CONTEXT    | SUB      | LINE  | FILE    | HASARGS
                  | IS_REQUIRE | EVALTEXT | HINTS | BITMASK |
               ));

   foreach my $c ( reverse @{$callers} ) {
      $table->load(
         [
           '|', $c->{context},
           '|', $c->{sub},
           '|', $c->{line},
           '|', $c->{file},
           '|', $c->{hasargs},
           '|', $c->{isreq},
           '|', $c->{evaltext},
           '|', $c->{hints},
           '|', $c->{bitmask},
           '|'
         ],
      );
   }

   my $name = $opt->{name} ? "FOR $opt->{name} " : "";
   my $top  = qq{| DUMPING CALLER STACK $name |\n};

   my $rv   = "\n" . ( '-' x (length($top) - 1) ) . "\n" . $top
            . $table->rule( '-', '+')
            . $table->title
            . $table->rule( '-', '+')
            . $table->body
            . $table->rule( '-', '+')
            ;

   return $rv;
}

package Text::Template::Simple::Cache;
use strict;
use vars qw($VERSION);
use constant CACHE_PARENT => 0;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util qw( DEBUG LOG ishref fatal );
use Carp qw( croak );

$VERSION = '0.79_03';

my $CACHE = {}; # in-memory template cache

sub new {
   my $class  = shift;
   my $parent = shift || fatal('tts.cache.new.parent');
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
      opendir CDIRH, $cdir or fatal( 'tts.cache.opendir' => $cdir, $! );
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $file;

      while ( defined( $file = readdir CDIRH ) ) {
         next if $file !~ m{ ( .* $ext) \z}xmsi;
         $file = File::Spec->catfile( $parent->[CACHE_DIR], $1 );
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
   fatal('tts.cache.dumper.hash')        if not ishref $param;
   my %valid = map { $_, $_ } qw( ids structure );
   fatal('tts.cache.dumper.type', $type) if not $valid{ $type };
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
         fatal('tts.cache.dumper' => $Data::Dumper::VERSION) if !$d->can('Deparse');
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
         my $dsv = Devel::Size->VERSION;
         LOG( DEBUG => "Devel::Size v$dsv is loaded." )
            if DEBUG();
         fatal('tts.cache.develsize.buggy', $dsv) if $dsv < 0.72;
         my $size = eval { Devel::Size::total_size( $CACHE ) };
         fatal('tts.cache.develsize.total', $@) if $@;
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

   fatal('tts.cache.pformat') if @_ % 2;

   my %opt = @_;
   my $id  = $parent->connector('Cache::ID')->new;
   my $cid = $opt{id}   ? $id->generate($opt{id}  , 'custom')
           : $opt{data} ? $id->generate($opt{data}          )
           :              fatal('tts.cache.incache');

   if ( my $cdir = $parent->[CACHE_DIR] ) {
      require File::Spec;
      return -e File::Spec->catfile( $cdir, $cid . CACHE_EXT ) ? 1 : 0;
   }
   else {
      return exists $CACHE->{ $cid } ? 1 : 0;
   }
}

sub _is_meta_version_old {
   my $self = shift;
   my $v    = shift;
   return 1 if ! $v; # no version? archaic then
   my $pv = PARENT->VERSION;
   foreach my $i ( $v, $pv ) {
      $i  =~ tr/_//d; # underscore versions cause warnings
      $i +=  0;       # force number
   }
   return 1 if $v < $pv;
   return;
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
            fatal('tts.cache.hit.meta', $@) if $@;
         }
         if ( $self->_is_meta_version_old( $meta{VERSION} ) ) {
            my $id = $parent->[FILENAME] || $cache_id;
            warn "(This messeage will only appear once) $id was compiled with"
                ." an old version of " . PARENT . ". Resetting cache.";
            return;
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

         fatal('tts.cache.hit.cache', $error) if $error;
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
            VERSION      => PARENT->VERSION,
         );

         my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT);
         my $fh    = IO::File->new;
         $fh->open($cache, '>') or fatal('tts.cache.populate.write', $cache, $!);
         flock $fh, Fcntl::LOCK_EX() if IS_FLOCK;
         $parent->io->layer($fh);
         my $warn =  $parent->_mini_compiler(
                        $parent->_internal('disk_cache_comment'),
                        {
                           NAME => PARENT->_class_id,
                           DATE => scalar localtime time,
                        }
                     );
         print $fh '#META:' . $self->_set_meta(\%meta) . "\n", $warn, $parsed; 
         flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
         close $fh;
         chmod(CACHE_FMODE, $cache) || fatal('tts.cache.populate.chmod');

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
      croak $parent->[VERBOSE_ERRORS]
            ? $parent->_mini_compiler( $parent->_internal('compile_error'), {
               CID => $cid,
               ERROR => $error,
               PARSED => $parsed,
               TIDIED => $tidied,
                                                                        } )
            : $error
            ;
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
   LOG( DESTROY => ref $self ) if DEBUG();
   $self->[CACHE_PARENT] = undef;
   @{$self} = ();
   return;
}

package Text::Template::Simple;
use strict;
use vars qw($VERSION);

$VERSION = '0.79_03';

use File::Spec;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Dummy;
use Text::Template::Simple::Compiler;
use Text::Template::Simple::Compiler::Safe;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Tokenizer;
use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Cache::ID;
use Text::Template::Simple::Cache;
use Text::Template::Simple::IO;

use base qw(
   Text::Template::Simple::Base::Compiler
   Text::Template::Simple::Base::Examine
   Text::Template::Simple::Base::Include
   Text::Template::Simple::Base::Parser
);

my %CONNECTOR = ( # Default classes list
   'Cache'     => 'Text::Template::Simple::Cache',
   'Cache::ID' => 'Text::Template::Simple::Cache::ID',
   'IO'        => 'Text::Template::Simple::IO',
   'Tokenizer' => 'Text::Template::Simple::Tokenizer',
);

my %DEFAULT = ( # default object attributes
   delimiters       => [ DELIMS ], # default delimiters
   cache            =>  0,    # use cache or not
   cache_dir        => '',    # will use hdd intead of memory for caching...
   strict           =>  1,    # set to false for toleration to un-declared vars
   safe             =>  0,    # use safe compartment?
   header           =>  0,    # template header. i.e. global codes.
   add_args         => '',    # will unshift template argument list. ARRAYref.
   warn_ids         =>  0,    # warn template ids?
   capture_warnings =>  0,    # bool
   iolayer          => '',    # I/O layer for filehandles
   stack            => '',    # dump caller stack?
   user_thandler    => undef, # user token handler callback
   monolith         =>  0,    # use monolithic template & cache ?
   include_paths    => [],    # list of template dirs
   verbose_errors   =>  0,    # bool
   pre_chomp        => CHOMP_NONE,
   post_chomp       => CHOMP_NONE,
   taint_mode       => TAINT_CHECK_NORMAL,
);

my @EXPORT_OK = qw( tts );

sub import {
   my $class = shift;
   my $caller = caller;
   my @args   = @_ or return;
   my %ok     = map { $_, $_ } @EXPORT_OK;

   no strict qw( refs );
   foreach my $name ( @args ) {
      fatal('tts.main.import.invalid', $name, $class) if ! $ok{$name};
      fatal('tts.main.import.undef',   $name, $class) if ! defined &{ $name   };
      my $target = $caller . '::' . $name;
      fatal('tts.main.import.redefine', $name, $caller) if defined &{ $target };
      *{ $target } = \&{ $name }; # install
   }

   return;
}

sub tts {
   my @args = @_;
   fatal('tts.main.tts.args') if ! @args;
   my @new  = ishref($args[0]) ? %{ shift(@args) } : ();
   return __PACKAGE__->new( @new )->compile( @args );
}

sub new {
   my $class = shift;
   my %param = scalar(@_) % 2 ? () : (@_);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   LOG( CONSTRUCT => $self->_class_id . " @ ".(scalar localtime time) )
      if DEBUG();

   my($fid, $fval);
   INITIALIZE: foreach my $field ( keys %DEFAULT ) {
      $fid = uc $field;
      next INITIALIZE if ! $class->can($fid);
      $fid  = $class->$fid();
      $fval = delete $param{$field};
      $self->[$fid] = defined $fval ? $fval : $DEFAULT{$field};
   }

   foreach my $bogus ( keys %param ) {
      warn "'$bogus' is not a known parameter. Did you make a typo?";
   }

   $self->_init;
   return $self;
}

sub connector {
   my $self = shift;
   my $id   = shift || fatal('tts.main.connector.args');
   return $CONNECTOR{ $id } || fatal('tts.main.connector.invalid', $id);
}

sub cache { shift->[CACHE_OBJECT] }
sub io    { shift->[IO_OBJECT]    }

sub compile {
   my $self  = shift;
   my $rv    = $self->_compile( @_ );
   # we need to reset this to prevent false positives
   # the trick is: this is set in _compile() and sub includes call _compile()
   # instead of compile(), so it will only be reset here
   $self->[COUNTER_INCLUDE] = undef;
   return $rv;
}

# -------------------[ P R I V A T E   M E T H O D S ]------------------- #

sub _init {
   my $self = shift;
   my $d    = $self->[DELIMITERS];
   my $bogus_args = $self->[ADD_ARGS] && ! isaref($self->[ADD_ARGS]);

   fatal('tts.main.bogus_args')   if $bogus_args;
   fatal('tts.main.bogus_delims') if ! isaref( $d ) || $#{ $d } != 1;
   fatal('tts.main.dslen')        if length($d->[DELIM_START]) < 2;
   fatal('tts.main.delen')        if length($d->[DELIM_END])   < 2;
   fatal('tts.main.dsws')         if $d->[DELIM_START] =~ m{\s}xms;
   fatal('tts.main.dews')         if $d->[DELIM_END]   =~ m{\s}xms;

   $self->[TYPE]           = '';
   $self->[COUNTER]        = 0;
   $self->[FAKER]          = $self->_output_buffer_var;
   $self->[FAKER_HASH]     = $self->_output_buffer_var('hash');
   $self->[FAKER_SELF]     = $self->_output_buffer_var('self');
   $self->[INSIDE_INCLUDE] = -1; # must be -1 not 0
   $self->[NEEDS_OBJECT]   =  0; # does the template need $self ?
   $self->[DEEP_RECURSION] =  0; # recursion detector

   fatal('tts.main.init.thandler')
      if $self->[USER_THANDLER] && ! iscref($self->[USER_THANDLER]);

   fatal('tts.main.init.include')
      if $self->[INCLUDE_PATHS] && ! isaref($self->[INCLUDE_PATHS]);

   $self->[IO_OBJECT] = $self->connector('IO')->new(
                           $self->[IOLAYER],
                           $self->[INCLUDE_PATHS],
                           $self->[TAINT_MODE],
                        );

   if ( $self->[CACHE_DIR] ) {
      $self->[CACHE_DIR] = $self->io->validate( dir => $self->[CACHE_DIR] )
                           or fatal( 'tts.main.cdir' => $self->[CACHE_DIR] );
   }

   $self->[CACHE_OBJECT] = $self->connector('Cache')->new($self);

   return;
}

sub _output_buffer_var {
   my $self = shift;
   my $type = shift || 'scalar';
   my $id   = $type eq 'hash'  ? {}
            : $type eq 'array' ? []
            :                    \my $fake
            ;
   $id  = "$id";
   $id .= int( rand($$) ); # . rand() . time;
   $id  =~ tr/a-zA-Z_0-9//cd;
   $id  =~ s{SCALAR}{SELF}xms if $type eq 'self';
   return '$' . $id;
}

sub _class_id {
   my $self = shift;
   my $class = ref($self) || $self;
   return sprintf( "%s v%s", $class, $self->VERSION() );
}

sub _tidy {
   my $self = shift;
   my $code = shift;

   TEST_TIDY: {
      local($@, $SIG{__DIE__});
      eval { require Perl::Tidy; };
      if ( $@ ) { # :(
         $code =~ s{;}{;\n}xmsgo; # new lines makes it easy to debug
         return $code;
      }
   }

   # We have Perl::Tidy, yay!
   my($buf, $stderr);
   my @argv; # extra arguments

   Perl::Tidy::perltidy(
      source      => \$code,
      destination => \$buf,
      stderr      => \$stderr,
      argv        => \@argv,
   );

   LOG( TIDY_WARNING => $stderr ) if $stderr;
   return $buf;
}

sub _needs_object {
   my $self = shift;
   $self->[NEEDS_OBJECT]++;
   return $self;
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG();
   undef $self->[CACHE_OBJECT];
   undef $self->[IO_OBJECT];
   @{ $self } = ();
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple - Simple text template engine

=head1 SYNOPSIS

   use Text::Template::Simple;
   my $tts = Text::Template::Simple->new();
   print $tts->compile( $FILEHANDLE );
   print $tts->compile('Hello, your perl is at <%= $^X %>');
   print $tts->compile(
            'hello.tts', # the template file
            [ name => 'Burak', location => 'Istanbul' ]
         );

Where C<hello.tts> has this content:

   <% my %p = @_; %>
   Hello <%= $p{name} %>,
   I hope it's sunny in <%= $p{location} %>.
   Local time is <%= scalar localtime time %>

=head1 DESCRIPTION

B<WARNING>! This is the monolithic version of Text::Template::Simple
generated with an automatic build tool. If you experience problems
with this version, please install and use the supported standard
version. This version is B<NOT SUPPORTED>.

This document describes version C<0.79_03> of C<Text::Template::Simple>
released on C<1 May 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

This is a simple template module. There is no extra template/mini 
language. Instead, it uses Perl as the template language. Templates
can be cached on disk or inside the memory via the internal cache 
manager. It is also possible to use static/dynamic includes,
pass parameters to includes and apply filters on them.
Also see L<Text::Template::Simple::API> for the full API definiton.

=head1 SYNTAX

Template syntax is very simple. There are few kinds of delimiters:

=over 4

=item *

C<< <% %>  >> Code Blocks

=item *

C<< <%= %> >> Self-printing Blocks

=item *

C<< <%! %> >> Escaped Delimiters

=item *

C<< <%+ %> >> Static Include Directives

=item *

C<< <%* %> >> Dynamic include directives

=item *

C<< <%# %> >> Comment Directives

=item *

C<< <%| %> >> Blocks with commands

=back

A simple example:

   <% foreach my $x (@foo) { %>
      Element is <%= $x %>
   <% } %>

Do not directly use print() statements, since they'll break the template
compilation. Use the self printing C<< <%= %> >> blocks.

It is also possible to alter the delimiters:

   $tts = Text::Template::Simple->new(
      delimiters => [qw/<?perl ?>/],
   );

then you can use them inside templates:

   <?perl
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   ?>
   Element is <?perl= $x ?>
   <?perl } ?>

If you need to remove a code temporarily without deleting, or need to add
comments:

   <%#
      This
      whole
      block
      will
      be
      ignored
   %>

If you put a space before the pound sign, the block will be a code block:

   <%
      # this is normal code not a comment directive
      my $foo = 42;
   %>

If you want to include a text or html file, you can use the
static include directive:

   <%+ my_other.html %>
   <%+ my_other.txt  %>

Included files won't be parsed and included statically. To enable
parsing for the included files, use the dynamic includes:

   <%* my_other.html %>
   <%* my_other.txt  %>

Interpolation is also supported with both kinds of includes, so the following
is valid code:

   <%+ "/path/to/" . $txt    %>
   <%* "/path/to/" . $myfile %>

=head2 Chomping

Chomping is the removal of whitespace before and after your directives. This
can be useful if you're generating plain text (instead of HTML which'll ignore
spaces most of the time). You can either remove all space or replace multiple
whitespace with a single space (collapse). Chomping can be enabled per
directive or globally via options to the constructor.
See L<Text::Template::Simple::API/pre_chomp> and
L<Text::Template::Simple::API/post_chomp> options to
L<Text::Template::Simple::API/new> to globally enable chomping.

Chomping is enabled with second level commands for all directives. Here is
a list of commands:

   -   Chomp
   ~   Collapse
   ^   No chomp (override global)

All directives can be chomped. Here are some examples:

Chomp:

   raw content
   <%- my $foo = 42; -%>
   raw content
   <%=- $foo -%>
   raw content
   <%*- /mt/dynamic.tts  -%>
   raw content

Collapse:

   raw content
   <%~ my $foo = 42; ~%>
   raw content
   <%=~ $foo ~%>
   raw content
   <%*~ /mt/dynamic.tts  ~%>
   raw content

No chomp:

   raw content
   <%^ my $foo = 42; ^%>
   raw content
   <%=^ $foo ^%>
   raw content
   <%*^ /mt/dynamic.tts  ^%>
   raw content

It is also possible to mix the chomping types:

   raw content
   <%- my $foo = 42; ^%>
   raw content
   <%=^ $foo ~%>
   raw content
   <%*^ /mt/dynamic.tts  -%>
   raw content

For example this template:

   Foo
   <%- $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   FooBar

And this one:

   Foo
   <%~ $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   Foo Bar

Chomping is inspired by Template Toolkit (mostly the same functionality,
although TT seems to miss collapse/no-chomp per directive option).

=head2 Accessing Template Names

You can use C<$0> to get the template path/name inside the template:

   I am <%= $0 %>

=head2 Escaping Delimiters

If you have to build templates like this:

   Test: <%abc>

or this:

   Test: <%abc%>

This will result with a template compilation error. You have to use the
delimiter escape command C<!>:

   Test: <%!abc>
   Test: <%!abc%>

Those will be compiled as:

   Test: <%abc>
   Test: <%abc%>

Alternatively, you can change the default delimiters to solve this issue.
See the L<Text::Template::Simple::API/delimiters> option for
L<Text::Template::Simple::API/new> for more information on how to
do this.

=head2 Template Parameters

You can fetch parameters (passed to compile) in the usual perl way:

   <%
      my $foo = shift;
      my %bar = @_;
   %>
   Baz is <%= $bar{baz} %>

=head2 INCLUDE COMMANDS

Include commands are separated by pipes in an include directive.
Currently supported parameters are:

=over 4

=item *

PARAM

=item *

FILTER

=back

   <%+ /path/to/static.tts  | FILTER: MyFilter %>
   <%* /path/to/dynamic.tts | FILTER: MyFilter | PARAM: test => 123 %>

C<FILTER:> defines the list of filters to apply to the output of the include.
C<PARAM:> defines the parameter list to pass to the included file.

=head3 INCLUDE FILTERS

Use the include command C<FILTER:> (notice the colon in the command):

   <%+ /path/to/static.tts  | FILTER: First, Second        %>
   <%* /path/to/dynamic.tts | FILTER: Third, Fourth, Fifth %>

=head4 IMPLEMENTING INCLUDE FILTERS

Define the filter inside C<Text::Template::Simple::Dummy> with a C<filter_>
prefix:

   package Text::Template::Simple::Dummy;
   sub filter_MyFilter {
      # $tts is the current Text::Template::Simple object
      # $output_ref is the scalar reference to the output of
      #    the template.
      my($tts, $output_ref) = @_;
      $$output_ref .= "FILTER APPLIED"; # add to output
      return;
   }

=head3 INCLUDE PARAMETERS

Just pass the parameters as described above and fetch them via C<@_> inside
the included file.

=head2 BLOCKS

A block consists of a header part and the content.

   <%| HEADER;
       BODY
   %>

C<HEADER> includes the commands and terminated with a semicolon. C<BODY> is the
actual block content.

=head3 BLOCK FILTERS

B<WARNING> Block filters are considered to be experimental. They may be changed
or completely removed in the future.

Identical to include filters, but works on blocks of text:

   <%| FILTER: HTML, OtherFilter;
      <p>&FooBar=42</p>
   %>

Note that you can not use any variables in these blocks. They are static.

=head1 METHODS & FUNCTIONS

=head2 new

=head2 cache

=head2 compile

=head2 connector

=head2 io

=head2 tts

See L<Text::Template::Simple::API> for the technical/gory details.

=head1 EXAMPLES

TODO

=head1 ERROR HANDLING

You may need to C<eval> your code blocks to trap exceptions. Some recoverable
failures are silently ignored, but you can display them as warnings 
if you enable debugging.

=head1 BUGS

Contact the author if you find any bugs.

=head1 CAVEATS

=head2 No mini language

There is no mini-language. Only perl is used as the template
language. So, this may or may not be I<safe> from your point
of view. If this is a problem for you, just don't use this 
module. There are plenty of template modules with mini-languages
inside I<CPAN>.

=head2 Speed

There is an initialization cost and this'll show itself after
the first compilation process. The second and any following compilations
will be much faster. Using cache can also improve speed, since this'll
eliminate the parsing phase. Also, using memory cache will make
the program run more faster under persistent environments. But the 
overall speed really depends on your environment.

Internal cache manager generates ids for all templates. If you supply 
your own id parameter, this will improve performance.

=head2 Optional Dependencies

Some methods/functionality of the module needs these optional modules:

   Devel::Size
   Text::Table
   Perl::Tidy

=head1 SEE ALSO

L<Text::Template::Simple::API>, L<Apache::SimpleTemplate>, L<Text::Template>,
L<Text::ScriptTemplate>, L<Safe>, L<Opcode>.

=head2 MONOLITHIC VERSION

C<Text::Template::Simple> consists of C<15+> separate modules. If you are
after a single C<.pm> file to ease deployment, download the distribution
from a C<CPAN> mirror near you to get a monolithic C<Text::Template::Simple>.
It is automatically generated from the separate modules and distributed in
the C<monolithic_version> directory.

However, be aware that the monolithic version is B<not supported>.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2009 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
