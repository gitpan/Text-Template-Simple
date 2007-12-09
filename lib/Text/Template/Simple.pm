package Text::Template::Simple::Dummy;
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.
use strict;

sub stack { # just a wrapper
   my $opt = shift || {};
   die "Parameters to stack() must be a HASH" if ref($opt) ne 'HASH';
   $opt->{frame} = 1;
   Text::Template::Simple::Caller->stack( $opt );
}

package Text::Template::Simple::Compiler;
# Compiling any code inside the template class is 
# like exploding a bomb in a public place.
# Since the compiled code will have access to anything
# inside the compiler method (i.e. cache populator) and 
# to any package globals/lexicals (i.e. $self), they'll 
# all be accessible inside the template code...
#
# So, we explode the bomb in deep space instead ;)
use strict;

sub _compile { shift; return eval shift }

package Text::Template::Simple::Compiler::Safe;
# Safe compiler. Totally experimental
use strict;

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

package Text::Template::Simple::Caller;
use strict;

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

use Carp qw( croak );

sub stack {
   my $self    = shift;
   my $opt     = shift || {};
   die "Parameters to stack() must be a HASH" if ref($opt) ne 'HASH';
   my $frame   = $opt->{frame};
   my $type    = $opt->{type} || '';
      $frame ||= 0;
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

   return reverse @callers if ! $type;

   if ( $self->can( my $method = '_' . $type ) ) {
      return $self->$method( $opt, \@callers );
   }

   croak "Unknown caller stack type: $type";
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
   warn "Caller stack type 'html_table' is not yet implemented. "
       ."Changing the option to 'string' instead";
   shift->_string( @_ );
}

sub _text_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   eval { require Text::Table; };
   croak "Caller stack type 'text_table' requires Text::Table" if $@;

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

package Text::Template::Simple::Tokenizer;
use strict;
use constant CMD_CHAR      =>  0;
use constant CMD_ID        =>  1;
use constant CMD_CB        =>  2; # callback

use constant TOKEN_ID      =>  0;
use constant TOKEN_STR     =>  1;
use constant LAST_TOKEN    => -1;

use constant ID_DS         =>  0;
use constant ID_DE         =>  1;

use constant SUBSTR_LENGTH =>  1;

use Carp qw( croak );

my @COMMANDS = (
   #   cmd id        callback
   [ qw/ = CAPTURE        / ],
   [ qw/ * DYNAMIC   trim / ],
   [ qw/ + STATIC    trim / ],
   [ qw/ ! NOTADELIM      / ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS] = shift || croak "tokenize(): Start delimiter is missing";
   $self->[ID_DE] = shift || croak "tokenize(): End delimiter is missing";
   $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my $self       = shift;
   my $tmp        = shift || croak "tokenize(): Template string is missing";
   my $map_keys   = shift;
   my($ds, $de)   = @{ $self };
   my($qds, $qde) = map { quotemeta $_ } $ds, $de;

   my(@tokens, $inside, $last, $i, $j);

   OUT_TOKEN: foreach $i ( split /($qds)/, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ DELIMSTART => $i ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach $j ( split /($qde)/, $i ) {
         if ( $j eq $de ) {
            $last = $tokens[LAST_TOKEN];
            if ( $last->[TOKEN_ID] eq 'NOTADELIM' ) {
               $last->[TOKEN_STR] = $self->tilde( $last->[TOKEN_STR] . $de );
            }
            else {
               push @tokens, [ DELIMEND => $j ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   return \@tokens;
}

sub token_code {
   my $self     = shift;
   my $str      = shift;
   my $inside   = shift;
   my $map_keys = shift;
   my $tree     = shift;
   my $first    = substr $str, 0, SUBSTR_LENGTH;
   #my $last     = substr $str, length($str) - 1, SUBSTR_LENGTH;

   my($cmd, $len, $cb, $buf);
   TCODE: foreach $cmd ( @COMMANDS ) {
      if ( $first eq $cmd->[CMD_CHAR] ) {
         $len = length($str);
         $cb  = $cmd->[CMD_CB];
         $buf = substr $str, 1, $len - 1;
         if ( $cmd->[CMD_ID] eq 'NOTADELIM' && $inside ) {
            $buf = $self->[ID_DS] . $buf;
            $tree->[LAST_TOKEN][TOKEN_ID] = 'DISCARD';
         }
         $cb = 'quote' if $map_keys;
         return [
                  $map_keys ? 'RAW'              : $cmd->[CMD_ID],
                  $cb       ? $self->$cb( $buf ) : $buf
                ];
      }
   }

   return [ $map_keys ? 'MAPKEY' : 'CODE', $str                 ] if $inside;
   return [                         'RAW', $self->tilde( $str ) ];
}

sub tilde {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ \~ }{\\~}xmsg;
      $s;
}

sub quote {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ " }{\\"}xmsg;
      $s;
}

sub trim {
   my $self = shift;
   my $s    = shift;
      $s    =~ s{ \A \s+    }{}xms;
      $s    =~ s{    \s+ \z }{}xms;
      $s;
}

package Text::Template::Simple;
use strict;
use vars qw($VERSION $OID @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.49_07';

use constant IS_WINDOWS     => $^O eq 'MSWin32' || $^O eq 'MSWin64';
use constant DELIM_START    => 0;
use constant DELIM_END      => 1;
use constant RE_NONFILE     => qr{ [ \n \r < > \* \? ] }xmso;
use constant RE_DUMP_ERROR  => qr{Can\'t locate object method "first" via package "B::SVOP"};
use constant RESUME_NOSTART => 1; # bool
use constant COMPILER       => __PACKAGE__.'::Compiler';       # The compiler
use constant COMPILER_SAFE  => __PACKAGE__.'::Compiler::Safe'; # Safe compiler
use constant DUMMY_CLASS    => __PACKAGE__.'::Dummy';          # Dummy class
use constant MAX_FL         => 80;                             # Maximum file name length
use constant CACHE_EXT      => '.tmpl.cache';                  # disk cache extension
use constant STAT_SIZE      => 7;
use constant STAT_MTIME     => 9;
use constant DELIMS         => qw( <% %> );                    # default delimiter pair
use constant NEW_PERL       => $] >= 5.008;

use constant IS_FLOCK       => sub {
   # are we running under dumb OS?
   if ( IS_WINDOWS ) {
      return Win32::IsWin95() ? 0 : 1;
   }
   return 1; # TODO: test flock() directly at this point
   return 0; # disable by default
}->();

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

# see _parse();
use constant MAP_KEYS_CHECK => sub {
   my $tmp = q(
         <%BUF%> .= exists <%HASH%>->{"<%KEY%>"}
                  ? (
                     defined <%HASH%>->{"<%KEY%>"}
                     ? <%HASH%>->{"<%KEY%>"}
                     : "[ERROR] Key not defined: <%KEY%>"
                     )
                  : "[ERROR] Invalid key: <%KEY%>"
                  ;
   );
   $tmp =~ s/\n//xmsg;
   $tmp =~ s/\s{2,}/ /xmsg;
   return $tmp;
}->();

use constant MAP_KEYS_INIT     => q(<%BUF%> .= <%HASH%>->{"<%KEY%>"} || '';);
use constant MAP_KEYS_DEFAULT  => q(<%BUF%> .= <%HASH%>->{"<%KEY%>"};);

use constant COMPILE_ERROR_TMP => <<'TEMPLATE_CONSTANT';
Error compiling code fragment (cache id: %s):

%s
-------------------------------
PARSED CODE (VERBATIM):
-------------------------------

%s

-------------------------------
PARSED CODE    (with \n added):
-------------------------------

%s
TEMPLATE_CONSTANT

use constant DISK_CACHE_COMMENT => <<"TEMPLATE_CONSTANT";
# !!!   W A R N I N G      W A R N I N G      W A R N I N G   !!!
# This file is automatically generated by %s v%s on %s.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
#
#
#
# [line 10]
TEMPLATE_CONSTANT

# object fields
BEGIN { $OID = -1 } # init object field id counter
use constant DELIMITERS     => ++$OID;
use constant AS_STRING      => ++$OID;
use constant DELETE_WS      => ++$OID;
use constant FAKER          => ++$OID;
use constant FAKER_HASH     => ++$OID;
use constant CACHE          => ++$OID;
use constant CACHE_DIR      => ++$OID;
use constant STRICT         => ++$OID;
use constant SAFE           => ++$OID;
use constant HEADER         => ++$OID;
use constant ADD_ARGS       => ++$OID;
use constant WARN_IDS       => ++$OID;
use constant FIX_UNCUDDLED  => ++$OID;
use constant TYPE           => ++$OID;
use constant COUNTER        => ++$OID;
use constant CID            => ++$OID;
use constant FILENAME       => ++$OID;
use constant RESUME         => ++$OID;
use constant IOLAYER        => ++$OID;
use constant STACK          => ++$OID;
# number of the last object field
use constant MAXOBJFIELD    =>   $OID;

use Carp qw( croak );
use Exporter ();

BEGIN {
   if ( IS_WINDOWS ) {
      local $@; # perl 5.5.4 does not seem to have a Win32.pm
      eval { require Win32; Win32->import; };
   }

   if ( NEW_PERL ) {
      eval q/
         sub _binmode { 
            my($fh, $layer) = @_;
            binmode $fh, ':'.$layer
         }
      /;
      die "Error compiling _binmode(): $@" if $@;
   }
   else {
      *_binmode = sub { binmode $_[0] };
   }
}

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
                  )],
   templates =>   [qw(
                     COMPILE_ERROR_TMP
                     DISK_CACHE_COMMENT
                     MAP_KEYS_CHECK
                     MAP_KEYS_INIT
                     MAP_KEYS_DEFAULT
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
                     CACHE
                     CACHE_DIR
                     STRICT
                     SAFE
                     HEADER
                     ADD_ARGS
                     WARN_IDS
                     FIX_UNCUDDLED
                     TYPE
                     COUNTER
                     CID
                     FILENAME
                     RESUME
                     IOLAYER
                     STACK
                     MAXOBJFIELD
                  )],
);
@EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

my $PID   = __PACKAGE__ . " v$VERSION";
my $DEBUG = 0;  # Disabled by default
my $CACHE = {}; # in-memory template cache
my $DIGEST;     # Will hold digester class name.
my %RESUME;     # Regexen for _resume

my %DEFAULT = ( # default object attributes
   delimiters    => [ DELIMS ], # default delimiters
   as_string     =>  0, # if true, resulting template will not be eval()ed
   delete_ws     =>  0, # delete whitespace-only fragments?
   cache         =>  0, # use cache or not
   cache_dir     => '', # will use hdd intead of memory for caching...
   strict        =>  1, # set to false for toleration to un-declared vars
   safe          =>  0, # use safe compartment?
   header        =>  0, # template header. i.e. global codes.
   add_args      => '', # will unshift template argument list. ARRAYref.
   warn_ids      =>  0, # warn template ids?
   iolayer       => '', # I/O layer for filehandles
   stack         => '',

   fix_uncuddled =>  0, # do some worst practice?
   resume        =>  0, # resume on error?
);

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

# -------------------[ CLASS  METHODS ]------------------- #

sub DEBUG {
   my $thing = shift;
   if ( defined $thing and ref $thing || $thing eq __PACKAGE__ ) {
      # so that one can use: $self->DEBUG or DEBUG
      $thing = shift;
   }
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
         warn "[FAILED    ] $mod - $file\n" if DEBUG();
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

   warn "[DIGESTER  ] $DIGEST\n" if DEBUG();
   return $DIGEST->new;
}

# -------------------[ OBJECT METHODS ]------------------- #

sub new {
   warn "[CONSTRUCT ] $PID @ ".(scalar localtime time)."\n" if DEBUG();
   my $class = shift;
   my %param = scalar(@_) % 2 ? () : (@_);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   my $fid;
   foreach my $field (keys %DEFAULT) {
      $fid = uc $field;
      next if not $class->can($fid);
      $fid = $class->$fid();
      $self->[$fid] = defined $param{$field} ? $param{$field}
                    :                          $DEFAULT{$field}
                    ;
   }

   $self->_init;
   return $self;
}

sub _init {
   my $self = shift;

   if ( $self->[CACHE_DIR] ) {
      require File::Spec;
      $self->[CACHE_DIR] = File::Spec->canonpath( $self->[CACHE_DIR] );
      my $wdir;
      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $self->[CACHE_DIR] );
         if( Win32::GetLastError() ) {
            warn "[   FAIL   ] Win32::GetFullPathName\n" if DEBUG();
            $wdir = ''; # croak "Win32::GetFullPathName: $^E";
         }
         else {
            my $ok = -e $wdir && -d _;
            $wdir  = '' if not $ok;
         }
      }
      $self->[CACHE_DIR] = $wdir if $wdir;
      my $ok = -e $self->[CACHE_DIR] && -d _;
      croak _fatal( CDIR => $self->[CACHE_DIR]) if not $ok;
   }

   my $d = $self->[DELIMITERS];
   my $bogus_args = $self->[ADD_ARGS] && ! _isaref($self->[ADD_ARGS]);
   my $ok_delim   = _isaref( $d )     && $#{ $d } == 1;
   croak _fatal('ARGS')   if     $bogus_args;
   croak _fatal('DELIMS') if not $ok_delim;

   $self->[TYPE]       = '';
   $self->[COUNTER]    = 0;
   $self->[CID]        = '';
   $self->[FAKER]      = $self->_output_buffer_var;
   $self->[FAKER_HASH] = $self->_output_buffer_var('i want a hash');

   return;
}

sub reset_cache {
   my $self  = shift;
   %{$CACHE} = ();

   if ( $self->[CACHE] && $self->[CACHE_DIR] ) {

      my $cdir = $self->[CACHE_DIR];
      local  *CDIRH;
      opendir CDIRH, $cdir or croak _fatal( CDIROPEN => $cdir, $! );
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $file;

      while ( defined( $file = readdir CDIRH ) ) {
         next if $file !~ m{$ext \z}xmsi;
         $file = File::Spec->catfile( $self->[CACHE_DIR], $file );
         warn "[UNLINK    ] $file\n" if DEBUG();
         unlink $file;
      }

      closedir CDIRH;
   }
}

sub dump_cache_ids {
   my $self = shift;
   my %p    = @_ % 2 ? () : (@_);
   my $VAR  = $p{varname} || '$CACHE_IDS';
   my @rv;

   if ( $self->[CACHE_DIR] ) {

      require File::Find;
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $id;
      my @list;

      my $wanted = sub {
         return if $_ !~ m{(.+?) $ext \z}xms;
         $id      = $1;
         $id      =~ s{.*[\\/]}{};
         push @list, $id;
      };

      File::Find::find({wanted => $wanted, no_chdir => 1}, $self->[CACHE_DIR]);

      @rv = sort @list;

   }
   else {
      @rv = sort keys %{ $CACHE };
   }

   require Data::Dumper;
   my $d = Data::Dumper->new( [ \@rv ], [ $VAR ]);
   return $d->Dump;
}

sub _get_disk_cache {
   require File::Find;
   require File::Spec;
   my $self = shift;
   my %disk_cache;
   my $ext = quotemeta CACHE_EXT;
   my $id;
   my($content, $ok, $_temp, $line);
   my $pattern = quotemeta '# [line 10]';

   my $wanted = sub {
      return if $_ !~ m{(.+?) $ext \z}xms;
      $id      = $1;
      $id      =~ s{.*[\\/]}{};
      $content = $self->_slurp( File::Spec->canonpath($_) );
      $ok      = 0;  # reset
      $_temp   = ''; # reset

      foreach $line ( split /\n/, $content ) {
         if ( $line =~ m{$pattern}xmso ) {
            $ok = 1,
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
 
   File::Find::find({ wanted => $wanted, no_chdir => 1 }, $self->[CACHE_DIR]);
   return \%disk_cache;
}

sub dump_cache {
   my $self    = shift;
   my %p       = @_ % 2 ? () : (@_);
   my $VAR     = $p{varname} || '$CACHE';
   my $deparse = $p{no_deparse} ? 0 : 1;
   require Data::Dumper;
   my $d;

   if ( $self->[CACHE_DIR] ) {
      $d = Data::Dumper->new( [ $self->_get_disk_cache ], [ $VAR ] );
   }
   else {
      $d = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
      if ( $deparse ) {
         croak _fatal(DUMPER => $Data::Dumper::VERSION) if !$d->can('Deparse');
         $d->Deparse(1);
      }
   }

   my $str;
   eval {
      $str = $d->Dump;
   };

   if ( my $error = $@ ) {
      if ( $deparse && $error =~ RE_DUMP_ERROR ) {
         my $name = ref($self) . '::dump_cache';
         warn "$name: An error occurred when dumping with deparse "
             ."(are you under mod_perl?). Re-Dumping without deparse...\n";
         warn "$error\n";
         my $nd = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
         $d->Deparse(0);
         $str = $nd->Dump;
      }
      else {
         croak $error;
      }
   }

   return $str;
}

sub cache_size {
   my $self = shift;
   return 0 if not $self->[CACHE]; # calculate only if cache is enabled

   if ( $self->[CACHE_DIR] ) { # disk cache
      require File::Find;
      my $total  = 0;
      my $ext    = quotemeta CACHE_EXT;

      my $wanted = sub {
         return if $_ !~ m{ $ext \z }xms; # only calculate "our" files
         $total += (stat $_)[STAT_SIZE];
      };

      File::Find::find({wanted => $wanted, no_chdir => 1}, $self->[CACHE_DIR]);
      return $total;

   }
   else { # in memory cache

      local $SIG{__DIE__};
      if ( eval { require Devel::Size; 1; } ) {
         warn "[DEBUG     ] Devel::Size v$Devel::Size::VERSION is loaded.\n"
            if DEBUG();
         return Devel::Size::total_size( $CACHE );
      }
      else {
         warn "Failed to load Devel::Size: $@" if DEBUG();
         return 0;
      }

   }
}

sub in_cache {
   my $self = shift;
   if ( not $self->[CACHE] ) {
      warn "Cache is disabled!" if DEBUG();
      return;
   }

   croak _fatal('PFORMAT') if @_ % 2;

   my %opt = @_;
   my $id  = $opt{id}   ? $self->idgen($opt{id}  , 'custom')
           : $opt{data} ? $self->idgen($opt{data}          )
           :              croak _fatal('INCACHE');

   if ( my $cdir = $self->[CACHE_DIR] ) {
      require File::Spec;
      return -e File::Spec->catfile( $cdir, $id . CACHE_EXT ) ? 1 : 0;
   }
   else {
      return exists $CACHE->{ $id } ? 1 : 0;
   }
}

sub idgen { # cache id generator
   my $self   = shift;
   my $data   = shift or croak "Can't generate id without data!";
   my $custom = shift;
   return $self->_fake_idgen( $data ) if $custom;
   return $self->DIGEST->add( $data )->hexdigest;
}

sub compile {
   my $self  = shift;
   my $tmpx  = shift or croak "No template specified";
   my $param = shift || [];
   my $opt   = shift || {
      id       => '', # id is AUTO
      map_keys => 0,  # use normal behavior
      chkmt    => 0,  # check mtime of file template?
   };

   croak "params must be an arrayref!" if not _isaref($param);
   croak "opts must be a hashref!"     if not _ishref($opt);

   my $tmp = $self->_examine($tmpx);
   if ( $opt->{chkmt} ) {
      if ( $self->[TYPE] eq 'FILE' ) { 
         $opt->{chkmt} = (stat $tmpx)[STAT_MTIME];
      }
      else {
         warn "[DISABLE MT] Disabling chkmt. Template is not a file\n"
            if DEBUG();
         $opt->{chkmt} = 0;
      }
   }

   warn "[ COMPILE  ] $opt->{id}\n" if defined $opt->{id} && DEBUG();

   my($CODE, $ok);
   my $cache_id = '';

   if ( $self->[CACHE] ) {
      my $method = $opt->{id};
      my @args   = (! $method || $method eq 'AUTO') ? ( $tmp              )
                 :                                    ( $method, 'custom' )
                 ;
      $cache_id  = $self->idgen( @args );

      if ( $CODE = $self->_cache_hit( $cache_id, $opt->{chkmt} ) ) {
         warn "[CACHE HIT ] $cache_id\n" if DEBUG();
         $ok = 1;
      }
   }

   $self->[CID]      = $cache_id; # if $cache_id;
   $self->[FILENAME] = $self->[TYPE] eq 'FILE' ? $tmpx : $self->[CID];

   if ( not $ok ) {
      # we have a cache miss; parse and compile
      warn "[CACHE MISS] $cache_id\n" if DEBUG();
      my $parsed = $self->_parse( $tmp, $opt->{map_keys}, $cache_id );
      $CODE      = $self->_populate_cache( $cache_id, $parsed, $opt->{chkmt} );
   }

   my   @args;
   push @args, @{ $self->[ADD_ARGS] } if $self->[ADD_ARGS];
   push @args, @{ $param };
   return $CODE->( @args );
}

sub get_id { shift->[CID] }

# -------------------[ P R I V A T E   M E T H O D S ]------------------- #

# these three (and _binmode() ) are functions not methods.
# TODO:
#   1) Convert to method for sub classing?
#   2) Add to the export list?
sub _isaref { $_[0] && ref($_[0]) && ref($_[0]) eq 'ARRAY' };
sub _ishref { $_[0] && ref($_[0]) && ref($_[0]) eq 'HASH'  };
sub _fatal  {
   my $ID  = shift;
   my $str = $ERROR{$ID} || croak "$ID is not defined as an error";
   return $str if not @_;
   return sprintf $str, @_;
}

sub _output_buffer_var {
   my $self    = shift;
   my $is_hash = shift;
   my $id      = ( $is_hash ? {} : \my $fake) . $$;# . rand() . time;
      $id      =~ tr/a-zA-Z_0-9//cd;
   return '$' . $id;
}

sub _fake_idgen {
   my $self = shift;
   my $data = shift or croak "Can't generate id without data!";
      $data =~ s{[^A-Za-z_0-9]}{_}xmsg;
   my $len = length( $data );
   if ( $len > MAX_FL ) { # limit file name length
      $data = substr $data, $len - MAX_FL, MAX_FL;
   }
   return $data;
}

sub _examine {
   my $self   = shift;
   my $tmp    = shift;
   my $length = 0;
   my $rv;
   if ( my $ref = ref($tmp) ) {
      croak _fatal(  NOTGLOB => $ref ) if $ref ne 'GLOB';
      croak _fatal( 'NOTFH'          ) if not  fileno $tmp;
      # hmmm... require Fcntl; flock $tmp, Fcntl::LOCK_SH() if IS_FLOCK;
      local $/;
      $rv = <$tmp>;
      #flock $tmp, Fcntl::LOCK_UN() if IS_FLOCK;
      close $tmp; # ??? can this be a user option?
      $self->[TYPE] = 'GLOB';
   }
   else {
      my $length = length $tmp;
      if ( $length  <=  255 and $tmp !~ RE_NONFILE and -e $tmp and not -d _ ) {
         $self->[TYPE] = 'FILE';
         $rv = $self->_slurp($tmp);
      }
      else {
         $self->[TYPE] = 'STRING';
         $rv = $tmp;
      }
   }
   warn "[ EXAMINE  ] ".$self->[TYPE]."; LENGTH: $length\n" if DEBUG();
   return $rv;
}

sub _iolayer {
   return if ! NEW_PERL;
   my $self  = shift;
   my $fh    = shift || croak "_iolayer(): Filehandle is absent";
   my $layer = $self->[IOLAYER]; # || croak "_iolayer(): I/O Layer is absent";
   _binmode( $fh, $layer ) if $self->[IOLAYER];
   return;
}

sub _slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my $fh   = IO::File->new;
   $fh->open($file, 'r') or croak "Error opening $file for reading: $!";
   flock $fh, Fcntl::LOCK_SH() if IS_FLOCK;
   $self->_iolayer( $fh );
   local $/;
   my $tmp = <$fh>;
   flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
   $fh->close;
   return $tmp;
}

sub _compiler { shift->[SAFE] ? COMPILER_SAFE : COMPILER }

sub _wrap_compile {
   my $self   = shift;
   my $parsed = shift or croak "nothing to compile";
   warn "CID: ".$self->[CID]."\n" if $self->[WARN_IDS] && $self->[CID];
   warn "[ COMPILER ] ".($self->[SAFE] ? 'Safe' : 'Normal')."\n" if DEBUG();
   my($CODE, $error);

   $CODE = $self->_compiler->_compile($parsed);

   if( $error = $@ ) {
      my $error2;
      if ( $self->[RESUME] ) {
         $CODE = sub { return qq~[$PID Fatal Error] $error~ };
         $error2 = $@;
      }
      $error .= $error2 if $error2;
   }
   return $CODE, $error;
}

sub _cache_hit {
   my $self     = shift;
   my $cache_id = shift;
   my $chkmt    = shift || 0;
   my($CODE, $error);

   if ( my $cdir = $self->[CACHE_DIR] ) {
      require File::Spec;
      my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT );

      if ( -e $cache && not -d _ && -f _ ) {
         my $disk_cache = $self->_slurp($cache);

         if ( $chkmt ) {
            if ( $disk_cache =~ m{^#(\d+)#} ) {
               my $mtime  = $1;
               if ( $mtime != $chkmt ) {
                  warn "[MTIME DIFF]\tOLD: $mtime\n\t\tNEW: $chkmt\n"
                     if DEBUG();
                  return; # i.e.: Update cache
               }
            }
         }

         ($CODE, $error) = $self->_wrap_compile($disk_cache);
         croak "Error loading from disk cache: $error" if $error;
         warn "[FILE CACHE]\n" if DEBUG();
         #$self->[COUNTER]++;
         return $CODE;
      }

   }
   else {
      if ( $chkmt ) {
         my $mtime = $CACHE->{$cache_id}{MTIME} || 0;

         if ( $mtime != $chkmt ) {
            warn "[MTIME DIFF]\tOLD: $mtime\n\t\tNEW: $chkmt\n" if DEBUG();
            return; # i.e.: Update cache
         }

      }
      warn "[MEM CACHE ]\n" if DEBUG();
      return $CACHE->{$cache_id}->{CODE};
   }
   return;
}

sub _populate_cache {
   my $self     = shift;
   my $cache_id = shift;
   my $parsed   = shift;
   my $chkmt    = shift;
   my($CODE, $error);

   if ( $self->[CACHE] ) {
      if ( my $cdir = $self->[CACHE_DIR] ) {
         require File::Spec;
         require Fcntl;
         require IO::File;

         my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT);
         my $fh    = IO::File->new;
         $fh->open($cache, '>') or croak "Error writing disk-cache $cache : $!";
         flock $fh, Fcntl::LOCK_EX() if IS_FLOCK;
         $self->_iolayer($fh);
         print $fh $chkmt ? "#$chkmt#\n" : "##\n",
                   $self->_cache_comment,
                   $parsed; 
         flock $fh, Fcntl::LOCK_UN() if IS_FLOCK;
         close $fh;

         ($CODE, $error) = $self->_wrap_compile($parsed);
         warn "[DISK POPUL] $cache_id\n" if DEBUG() > 2;
      } 
      else {
         $CACHE->{$cache_id} = {CODE => undef, MTIME => 0}; # init
         ($CODE, $error) = $self->_wrap_compile($parsed);
         $CACHE->{$cache_id}->{CODE}  = $CODE;
         $CACHE->{$cache_id}->{MTIME} = $chkmt if $chkmt;
         warn "[MEM POPUL ] $cache_id\n" if DEBUG() > 2;
      }
   }
   else {
      ($CODE, $error) = $self->_wrap_compile($parsed); # cache is disabled
      warn "[NC   POPUL] $cache_id\n" if DEBUG() > 2;
   }

   if ( $error ) {
      my $cid = $cache_id ? $cache_id : 'N/A';
      my $p   = $parsed;
         $p   =~ s{;}{;\n}xmsgo; # new lines makes it easy to debug
      croak sprintf COMPILE_ERROR_TMP, $cid, $error, $parsed, $p;
   }
   $self->[COUNTER]++;
   return $CODE;
}

sub _parse {
   my $self     = shift;
   my $raw      = shift;
   my $map_keys = shift; # code sections are hash keys
   my $cache_id = shift;

   my $resume   = $self->[RESUME] || '';
   my $ds       = $self->[DELIMITERS][DELIM_START];
   my $de       = $self->[DELIMITERS][DELIM_END  ];
   my $faker    = $self->[FAKER];
   my $buf_hash = $self->[FAKER_HASH];
   my $toke     = Text::Template::Simple::Tokenizer->new( $ds, $de );
   my $code     = '';
   my $inside   = 0;

   my($mko, $mkc, $mki);

   if ( $map_keys ) {
      $mki = $map_keys eq 'init';
      $mkc = $map_keys eq 'check';
      $mko = $mki ? MAP_KEYS_INIT
           : $mkc ? MAP_KEYS_CHECK
           :        MAP_KEYS_DEFAULT;

      $mko =~ s/<%BUF%>/$faker/xmsg;
      $mko =~ s/<%HASH%>/$buf_hash/xmsg;
      $mko =~ s/<%KEY%>/%s/xmsg;
   }

   $self->_fix_uncuddled(\$raw, $ds, $de) if $self->[FIX_UNCUDDLED];

   # fetch and walk the tree
   my($id, $str);
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $map_keys ) } ) {
      ($id, $str) = @{ $token };
      next PARSER if $id eq 'DISCARD';

      if ( $id eq 'DELIMSTART' ) { $inside++; next PARSER; }
      if ( $id eq 'DELIMEND'   ) { $inside--; next PARSER; }

      if ( $id eq 'RAW' || $id eq 'NOTADELIM' ) {
         $code .= ";$faker .= q~$str~;";
      }
      elsif ( $id eq 'CODE' ) {
         $code .= $resume ? $self->_resume($str) : $str;
      }
      elsif ( $id eq 'CAPTURE' ) {
         $code .= $faker;
         $code .= $resume ? $self->_resume($str, RESUME_NOSTART)
                :           " .= sub { $str }->();";
      }
      elsif ( $id eq 'DYNAMIC' || $id eq 'STATIC' ) {
         $code .= "$faker .= sub {" . $self->_include($id, $str) . "}->();";
      }
      elsif ( $id eq 'MAPKEY' ) {
         $code .= sprintf $mko, $mkc ? ( ($str) x 5 ) : $str;
      }
      else {
         die "Unknown token: $id($str)";
      }
   }

   $self->[FILENAME] ||= '<ANON>';

   #warn "[CASE 'END'] state: $is_code; open: $is_open\n" if DEBUG();

   if ( $inside ) {
      my $type = $inside > 0 ? 'opening' : 'closing';
      croak "Unbalanced $type delimiter in template " . $self->[FILENAME];
   }

   my $wrapper;
   # build the anonymous sub
   $wrapper  = "package " . DUMMY_CLASS . ";";
   $wrapper .= 'use strict;'                   if $self->[STRICT];
   $wrapper .= 'sub { ';
   $wrapper .= $self->_add_stack( $cache_id )  if $self->[STACK];
   $wrapper .= $self->[HEADER].';'             if $self->[HEADER];
   $wrapper .= "my $faker = '';";
   $wrapper .= "my $buf_hash = {\@_};"         if $map_keys;
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . ";return $faker;";
   $wrapper .= '}';

   warn "\n\n#FRAGMENT\n$wrapper\n#/FRAGMENT\n"  if DEBUG() > 1;

   return $wrapper;
}

sub _add_stack {
   my $self    = shift;
   my $cs_name = shift || '<ANON TEMPLATE>';
   my $stack   = $self->[STACK] || '';

   return if lc($stack) eq 'off';

   my $type    = ($stack eq '1' || $stack eq 'yes' || $stack eq 'on')
               ? 'string'
               : $stack
               ;

   foreach my $e ( $cs_name, $type ) {
      $e =~ s{'}{\\'}xmsg;
   }

   return "warn stack( { type => '$type', name => '$cs_name' } );";
}

sub _include {
   my $self      = shift;
   my $type      = shift || '';
      $type      = lc $type;
   my $is_static = $type eq 'static';
   my $is_normal = $type eq 'normal' || $type eq 'dynamic';
   my $known     = $is_static || $is_normal;

   croak "Unknown include type: $type" if not $known;

   my $file = shift;
   my $err  = '['.($is_static ? ' static' : '').' include error ]';
   $file =~ s{\A \s+   }{}xms;
   $file =~ s{   \s+ \z}{}xms;
   -e $file  or return "q~$err '$file' does not exist~";
   -d $file and return "q~$err '$file' is a directory~";

   my $text;
   warn "[INCLUDE   ] $type => '$file'\n" if DEBUG();
   eval { $text = $self->_slurp($file) };
   return "q~$err $@~" if $@;

   if ( $is_normal ) {
      # creates endless recursive loop if template includes itself
      # cloning $self can help to overcome this issue
      return "q~$err dynamic include is disabled. file: '$file'~";
      $text = $self->_parse($text);
      return $text;
   }

   if ( $is_static ) {
      $text =~ s{\~}{\\~}xmsog;
      return 'q~'.$text.'~;';
   }

   return "$err This can not happen!";
}

sub _cache_comment {
   sprintf DISK_CACHE_COMMENT, ref(shift), $VERSION, scalar localtime time;
}

sub DESTROY {
   my $self   = shift || return;
   @{ $self } = ();
   return;
}

# Experimental and probably nasty stuff. Re-Write or remove!

sub _fix_uncuddled {
   my $self = shift;
   my $tmp  = shift;
   my $ds   = shift;
   my $de   = shift;
   warn "[  FIXING  ] Worst practice: Cuddling uncuddled else/elsif\n";
   # common part
   my $start = qr{
      $ds         # delimiter start
      (?:\s+|)    # ws or not
      \}          # block ending
      (?:\s+|)    # ws or not
      $de         # delimiter end
      (?:\s+|)    # ws or not
      $ds         # delimiter start
      (?:\s+|)    # ws or not
   }xms;
   # fix else
   $$tmp =~ s{
      $start
      else        # keyword
      (?:\s+|)    # ws or not
      \{          # block opening
      (?:\s+|)    # ws or not
      $de         # delimiter-end
   }{$ds\} else \{$de}xmsgo;
   # fix elsif
   $$tmp =~ s{
      $start
      elsif       # keyword
      (?:\s+|)    # ws or not
      \( (.+?) \) # elsif bool
      (?:\s+|)    # ws or not
      \{          # block opening
      (?:\s+|)    # ws or not
      $de
   }{$ds\} elsif ($1) \{$de}xmsgo;
   warn "#FIXED\n$$tmp\n#/FIXED\n" if DEBUG() > 2;
   return;
}

sub _set_resume_re {
   $RESUME{MY} = qr{
      # exclude my() declarations.
      (?:
         (?:my|local) (?:\s+|) \(       # my($foo)
         |
         (?:my|local) (?:\s+|) [\$\@\%] # my $foo
         |
         (?:my|local)[\$\@\%]           # my$foo
      )
      |
      (?:
         (?: unless|if|while|until|for|foreach )
         (?:\s+|)
         \(
      )
   }xms;
   $RESUME{CURLIES} = qr{ \A (?:\s+|) (?:[\{\}]) (?:\s+|)             \z }xms;
   $RESUME{ELSIF}   = qr{ \A (?:\s+|) (?:\})     (?:\s+|) (?:else|elsif) }xms;
   $RESUME{ELSE}    = qr{ \A (?:\s+|) \}         (?:\s+|)
                            else (?:\s+|) (?:\{) (?:\s+|) \z }xms;
   $RESUME{LOOP}    = qr{   (?:next|last|continue|redo)      }xms;
   return;
}

sub _resume {
   my $self    = shift;
   my $token   = shift           || return;
   my $nostart = shift           || 0;
   my $resume  = $self->[RESUME] || '';
   my $start   = $nostart ? '' : $self->[FAKER];
   my $void    = $nostart ? 0  : 1; # not a self-printing block

   $self->_set_resume_re() if not %RESUME;

   if ( $token && $resume && $token !~ $RESUME{MY} ) {
      #warn "[RESUME OK ] $token\n" if DEBUG > 1;
      if (
          $token !~ $RESUME{CURLIES} &&
          $token !~ $RESUME{ELSIF}   &&
          $token !~ $RESUME{ELSE}    &&
          $token !~ $RESUME{LOOP}
      ) {
         return $start
               ." .= sub {"
               ."local \$SIG{__DIE__};"
               ."my \@rrrrrrrrrrrv = eval { $token };"
               ."return qq([$PID Fatal Error] \$@) if \$@;"
               ."return '' if($void);"
               ."return \$rrrrrrrrrrrv[0] if \@rrrrrrrrrrrv == 1;"
               ."return +(\@rrrrrrrrrrrv);"
               ."}->();";
      }
   }
   #else {
   #   warn "[RESUME NOT] $token\n" if DEBUG > 1;
   #}

   return "$start .= $token;"
}

#sub _hasta_la_vista_baby {
#   caller(1)->isa(__PACKAGE__)
#      or croak +(caller 1)[3]."() is a private method!";
#   $_[0];
#}

#sub AUTOLOAD {
#   my $self  = shift;
#   my $class = ref($self) || __PACKAGE__;
#  (my $name  = $AUTOLOAD) =~ s{.*:}{};
#   croak qq~Unknown method name $name called via $class object~;
#}

1;

__END__

=head1 NAME

Text::Template::Simple - Simple text template engine

=head1 SYNOPSIS

   use Text::Template::Simple;
   my $template = Text::Template::Simple->new;
   my $tmp      = q~
   <%
      my %p = @_;
   %>
   
   <%=$p{str}%> : <%=scalar localtime time%>
   
   ~;
   print $template->compile($tmp, [str => 'Time now']);

=head1 DESCRIPTION

This is a simple template module. There is no extra template 
language. Instead, it uses Perl as a template language. Templates
can be cached on disk or inside the memory via internal cache 
manager.

=head1 SYNTAX

Template syntax is very simple. There are few kinds of delimiters:
code blocks (C<< <% %> >>), self-printing blocks (C<< <%= %> >>),
escaped delimiters (C<< <%! %> >>)
and static include directive (C<< <%+ %> >>):

   <%
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   %>
   Element is <%= $x %>
   <% } %>

do not directly use print() statements, since they'll break the code.
Use C<< <%= %> >> blocks. Delimiters can be altered:

   $template = Text::Template::Simple->new(
      delimiters => [qw/<?perl ?>/],
   );

then you can use them inside templates:

   <?perl
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   ?>
   Element is <?perl= $x ?>
   <?perl } ?>

If you want to include a text or html file, you can use the
static include directive:

   <%+ my_other.html %>
   <%+ my_other.txt  %>

Included files won't be parsed and included statically.

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
See the L</delimiters> option for L</new> for more information on how to
do this.

=head2 Template parameters

You can fetch parameters (passed to compile) in the usual perl way:

   <%
      my $foo = shift;
      my %bar = @_;
   %>
   Baz is <%= $bar{baz} %>

=head2 Special Variables

There is a special variable inside all templates. You must not
define a variable with the same name inside templates or alter
it's name before L</compile>.

=head1 METHODS

=head2 new

Creates a new template object and can take several parameters.

=head3 delimiters

Must be an array ref containing the two delimiter values: 
the opening delimiter and the closing delimiter:

   $template = Text::Template::Simple->new(
      delimiters => ['<?perl', '?>'],
   );

Default values are C<< <% >> and C<< %> >>. 

=head3 cache

Pass this with a true value if you want the cache feature.
In-memory cache will be used unless you also pass a L</cache_dir>
parameter.

=head3 cache_dir

If you want disk-based cache, set this parameter to a valid
directory path. You must also set L</cache> to a true value.

=head3 resume

If has a true value, the C<die()>able code fragments will not terminate
the compilation of remaining parts, the compiler will simply resume 
it's job. However, enabling this may result with a performance penalty
if cache is not enabled. If cache is enabled, the performance penalty
will show itself after every compilation process (upto C<2x> slower).

This option is currently experimental and uses more resources.
Only enable it for debugging.

CAVEAT: C<< <% use MODULE %> >> directives won't resume.

=head3 strict

If has a true value, the template will be compiled under strict.
Enabled by default.

=head3 safe

Set this to a true value if you want to execute the template
code in a safe compartment. Disabled by default and highly 
experimental. This option can also disable some template 
features.

If you want to enable some unsafe conditions, you have to define 
C<Text::Template::Simple::Compiler::Safe::permit> sub in
your controller code and return a list of permitted opcodes
inside that sub:

   sub Text::Template::Simple::Compiler::Safe::permit {
      my $class = shift;
      return qw(:default :subprocess); # enable backticks and system
   }

If this is not enough for you, you can define the safe compartment
all by yourself by defining 
C<Text::Template::Simple::Compiler::Safe::object>:

   sub Text::Template::Simple::Compiler::Safe::object {
      require Safe;
      my $safe = Safe->new('Text::Template::Simple::Dummy');
      $safe->permit(':browse');
      return $safe;
   }

C<:default>, C<require> and C<caller> are enabled opcodes, unless you 
define your own. You have to disable C<strict> option
to disable C<require> opcode. Disabling C<caller> will also make
your C<require>/C<use> calls die in perl 5.9.5 and later.

See L<Safe> and especially L<Opcode> for opcode lists and 
other details.

=head3 header

This is a string containing global elements (global to this particular
object) for templates. You can define some generally accessible variables
with this:

   $template = Text::Template::Simple->new(
      header => q~ my $foo = "bar"; ~,
   );

and then you can use it (without defining) inside any template that 
is compiled with C<$template> object:

   Foo is <%=$foo%>

=head3 add_args

ARRAYref. Can be used to add a global parameter list to the templates.

   $template = Text::Template::Simple->new(
      add_args => [qw(foo bar baz)],
   );

and then you can fetch them inside any template that is compiled with 
C<$template> object:

   <%
      my $foo = shift;
      my $bar = shift;
      my $baz = shift;
   %>
   Foo is <%=$foo%>. Bar is <%=$bar%>. Baz is <%=$baz%>

But it'll be logical to combine it with C<header> parameter:

   $template = Text::Template::Simple->new(
      header   => q~my $foo = shift;my $bar = shift;my $baz = shift;~,
      add_args => [qw(foo bar baz)],
   );

and then you can use it inside any template that is compiled with 
C<$template> object without manually fetching all the time:

   Foo is <%=$foo%>. Bar is <%=$bar%>. Baz is <%=$baz%>

Can be useful, if you want to define a default object:

   $template = Text::Template::Simple->new(
      header   => q~my $self = shift;~,
      add_args => [$my_default_object],
   );

and then you can use it inside any template that is compiled with 
C<$template> object without manually fetching:

   Foo is <%= $self->{foo} %>. Test: <%= $self->method('test') %>

=head3 warn_ids

If enabled, the module will warn you about compile steps using 
template ids. You must both enable this and the cache. If
cache is disabled, no warnings will be generated.

=head3 fix_uncuddled

If you are using uncuddled elses/elsifs (which became popular after
Damian Conway' s PBP Book) in your templates, this will break the parser.
If you supply this parameter with a true value, the parser will
reformat the data with cuddled versions before parsing it.

=head3 iolayer

This option does not have any effect under perls older than C<5.8.0>.
Set this to C<utf8> (no initial colon) if your I/O is C<UTF-8>. 
Not tested with other encodings.

=head3 stack

This option enables caller stack tracing for templates. The generated
list is sent to C<warn>. So, it is possible to capture
this data with a signal handler. Available options are:

   string
   html_comment
   html_table
   text_table  

C<html_comment> is the same as C<string> except that it also includes HTML
comment markers. C<text_table> needs the optional module C<Text::Table>.

This option is also available to all templates as a function named
C<stack> for individual stack dumping.
But, currently this interface is not documented.

=head2 compile DATA [, FILL_IN_PARAM, OPTIONS]

Compiles the template you have passed and manages template cache,
if you've enabled cache feature. Then it returns the compiled template.
Accepts three different types of data as the first parameter; 
a reference to a filehandle (C<GLOB>), a string or a file path 
(path to the template file).

=head3 First parameter (DATA)

The first parameter can take three different values; a filehandle,
a string or a file path. Distinguishing filehandles are easy, since
they'll be passed as a reference (but see the bareword issue below).
So, the only problem is distinguishing strings and file paths. 
C<compile> first checks if the string length is equal or less than
255 characters and then tests if a file with this name exists. If
all these tests fail, the string will be treated as the template 
text.

=head4 File paths

You can pass a file path as the first parameter:

   $text = $template->compile('/my/templates/test.tmpl');

=head4 Strings

You can pass a string as the first parameter:

   $text = $template->compile(q~
   <%for my $i (0..10) {%>
      counting <%=$i%>...
   <%}%>
   ~);

=head4 Filehandles

C<GLOB>s must be passed as a reference. If you are using bareword 
filehandles, be sure to pass it's reference or it'll be treated as a 
file path and your code will probably C<die>:

   open MYHANDLE, '/path/to/foo.tmpl' or die "Error: $!";
   $text = $template->compile(\*MYHANDLE); # RIGHT.
   $text = $template->compile( *MYHANDLE); # WRONG. Recognized as a file path
   $text = $template->compile(  MYHANDLE); # WRONG. Ditto. Will die under strict

or use the standard C<IO::File> module:

   use IO::File;
   my $fh = IO::File->new;
   $fh->open('/path/to/foo.tmpl', 'r') or die "Error: $!";
   $text = $template->compile($fh);

or you can use lexicals inside C<open> if you don't care about 
compatibility with older perl:

   open my $fh, '/path/to/foo.tmpl' or die "Error: $!";
   $text = $template->compile($fh);

Filehandles will be automatically closed.

=head3 FILL_IN_PARAM

An arrayref. Everything inside this will be accessible from the 
usual  C<@_> array inside templates.

=head3 OPTIONS

A hashref. Several template specific options can be set with
this parameter.

=head4 id

Controls the cache id generation. Can be useful, if you want to 
pass your own template id. If false or set to C<AUTO>, internal
mechanisms will be used to generate template keys.

=head4 map_keys

This will change the compiler behavior. If you enable this,
you can construct templates like this:

   This is "<%foo%>", that is "<%bar%>" and the other is "<%baz%>"

i.e.: only  the key names can be used instead of perl constructs.
and as you can see, "C<< <% >>" is used instead of "C<< <%= >>". 
C<map_keys> also disables usage of perl constructs. Only bare words 
can be used and you don't have to I<fetch> parameters via C<@_> 
inside the template. Here is an example:

   $text = $template->compile(
            q~This is "<%foo%>", that is "<%bar%>" 
              and the other is "<%baz%>"~,
            [
               foo => "blah 1",
               bar => "blah 2",
               baz => "blah 3",
            ],
            {
               map_keys => 1
            },
   );

Can be good (and simple) for compiling i18n texts. If you don't use 
C<map_keys>, the above code must be written as:

   $text = $template->compile(
            q~<%my(%l) = @_%>This is "<%=$l{foo}%>", that is "<%=$l{bar}%>" 
              and the other is "<%=$l{baz}%>"~,
            [
               foo => "blah 1",
               bar => "blah 2",
               baz => "blah 3",
            ],
   );

If C<map_keys> is set to 'init', then the uninitialized values 
will be initialized to an empty string. But beware; C<init> may cloak 
template errors. It'll silence I<uninitialized> warnings, but
can also make it harder to detect template errors.

If C<map_keys> is set to 'check', then the compiler will check for
the key's existence and check if it is defined or not.

=head4 chkmt

If you are using file templates (i.e.: not FH or not string) and you 
set this to a true value, modification time of templates will be checked
and compared for template change.

=head2 reset_cache

Resets the in-memory cache and deletes all cache files, 
if you are using a disk cache.

=head2 dump_cache

Returns a string version of the dumped in-memory or disk-cache. 
Cache is dumped via L<Data::Dumper>. C<Deparse> option is enabled
for in-memory cache. 

Early versions of C<Data::Dumper> don' t have a C<Deparse>
method, so you may need to upgrade your C<Data::Dumper> or
disable deparse-ing if you want to use this method.

C<dump_cache> accepts some arguments in C<< name => value >>
format:

=over 4

=item *

varname

Controls the name of the dumped structure.

=item *

no_deparse

If you set this to a true value, deparsing will be disabled

=back

=head2 dump_cache_ids

Returns a list including the names (ids) of the templates in
the cache.

=head2 idgen DATA

This may not have any meaning for the typical user. Used internally 
to generate unique ids for template C<DATA> (if cache is enabled).

=head2 get_id

Returns the current cache id (if there is any).

=head2 cache_size

Returns the total cache (disk or memory) size in bytes. If you 
are using memory cache, you must have L<Devel::Size> installed
on your system or your code will die.

=head2 in_cache data => TEMPLATE_DATA

=head2 in_cache id   => TEMPLATE_ID

This method can be called with C<data> or C<id> named parameter. If you 
use the two together, C<id> will be used:

   if($template->in_cache(id => 'e369853df766fa44e1ed0ff613f563bd')) {
      print "ok!";
   }

or

   if($template->in_cache(data => q~Foo is <%=$bar%>~)) {
      print "ok!";
   }

=head1 CLASS METHODS

These are all global (i.e.: not local to any particular object).

=head2 DEBUG

Used to enable/disable debugging. Debug information 
is generated as warnings:

   Text::Template::Simple->DEBUG(1); # enable
   Text::Template::Simple->DEBUG(0); # disable
   Text::Template::Simple->DEBUG(2); # more verbose

C<DEBUG> is disabled by default.

=head2 DIGEST

Returns the digester object:

   $digester = Text::Template::Simple->DIGEST;
   print $digester->add($data)->hexdigest;

=head1 CACHE MANAGER

Cache manager has two working modes. It can use disk files or
memory for the storage. Memory based cache is far more faster
than disk cache.

The template text is first parsed and compiled into an anonymous
perl sub source. Then an unique key is generated from your source 
data (you can by-pass key generation phase if you supply your own id 
parameter).

If in-memory cache is used, the perl source will be 
compiled into an anonymous sub inside the in-memory cache hash
and this compiled version will be used instead of continiously
parsing/compiling the same template.

If disk cache is used, a template file with the "C<.tmpl.cache>"
extension will be generated on the disk.

Using cache is recommended under persistent environments like 
C<mod_perl> and C<PerlEx>.

In-memory cache can use two or three times more space than disk-cache, 
but it is far more faster than disk cache. Disk cache can also be slower
than no-cache for small templates, since there is a little overhead 
when generating unique keys with the L</DIGESTER> and also there will
be a disk I/O. There is a modification time check option for disk
based templates (see L<compile|"compile DATA [, FILL_IN_PARAM, OPTIONS]">).

=head1 DIGESTER

Cache keys are generated with one of these modules:

   Digest::SHA
   Digest::SHA1
   Digest::SHA2
   Digest::SHA::PurePerl
   Digest::MD5
   MD5
   Digest::Perl::MD5

SHA algorithm seems to be more reliable for key generation, but
md5 is widely available and C<Digest::MD5> is in CORE.

=head1 EXAMPLES

TODO

=head1 ERROR HANDLING

You may need to C<eval> your code blocks to trap exceptions. Some 
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

=head1 SEE ALSO

For similar functionality, see L<Apache::SimpleTemplate>.
Also see L<Text::Template> for a similar 
functionality. L<HTML::Template::Compiled> has a similar approach
for compiled templates. There is another similar module
named L<Text::ScriptTemplate>. Also see L<Safe> and
L<Opcode>.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2007 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
