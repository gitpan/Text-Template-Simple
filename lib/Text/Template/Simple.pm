package Text::Template::Simple;
use strict;
use vars qw($VERSION);

$VERSION = '0.54_06';

use Carp qw( croak );
use Text::Template::Simple::Constants;
use Text::Template::Simple::Dummy;
use Text::Template::Simple::Compiler;
use Text::Template::Simple::Compiler::Safe;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Tokenizer;
use Text::Template::Simple::Util;
use Text::Template::Simple::Cache::ID;
use Text::Template::Simple::Cache;
use Text::Template::Simple::IO;
use File::Spec;

my %CONNECTOR = ( # Default classes list
   'Cache'     => 'Text::Template::Simple::Cache',
   'Cache::ID' => 'Text::Template::Simple::Cache::ID',
   'IO'        => 'Text::Template::Simple::IO',
   'Tokenizer' => 'Text::Template::Simple::Tokenizer',
);

my %DEFAULT = ( # default object attributes
   delimiters     => [ DELIMS ], # default delimiters
   cache          =>  0, # use cache or not
   cache_dir      => '', # will use hdd intead of memory for caching...
   strict         =>  1, # set to false for toleration to un-declared vars
   safe           =>  0, # use safe compartment?
   header         =>  0, # template header. i.e. global codes.
   add_args       => '', # will unshift template argument list. ARRAYref.
   warn_ids       =>  0, # warn template ids?
   iolayer        => '', # I/O layer for filehandles
   stack          => '',
   user_thandler  => undef, # user token handler callback
   monolith       =>  0, # use monolithic template & cache ?
   include_paths  => [],
   # TODO: Consider removing these
   resume         =>  0, # resume on error?
);

# internal code templates
my %INTERNAL = (
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
         undef,
         {
            _sub_inc => '<%TYPE%>'
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
);

sub new {
   my $class = shift;
   my %param = scalar(@_) % 2 ? () : (@_);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   LOG( CONSTRUCT => $self->_parser_id . " @ ".(scalar localtime time) )
      if DEBUG();

   my $fid;
   foreach my $field ( keys %DEFAULT ) {
      $fid = uc $field;
      next if not $class->can($fid);
      $fid = $class->$fid();
      $self->[$fid] = defined $param{$field} ? $param{$field} : $DEFAULT{$field};
   }

   $self->_init;
   return $self;
}

sub connector {
   my $self = shift;
   my $id   = shift             || croak "connector(): id is missing";
   my $name = $CONNECTOR{ $id } || croak "connector(): invalid id: $id";
   return $name;
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

sub _compile {
   my $self  = shift;
   my $tmpx  = shift || croak "No template specified";
   my $param = shift || [];
   my $opt   = shift || {};

   croak "params must be an arrayref!" if not isaref($param);
   croak "opts must be a hashref!"     if not ishref($opt);

   # set defaults
   $opt->{id}       ||= ''; # id is AUTO
   $opt->{map_keys} ||= 0;  # use normal behavior
   $opt->{chkmt}    ||= 0;  # check mtime of file template?
   $opt->{_sub_inc} ||= 0;  # are we called from a dynamic include op?

   my $tmp = $self->_examine( $tmpx );
   return $tmp if $self->[TYPE] eq 'ERROR';

   if ( $opt->{_sub_inc} ) {
      # TODO:generate a single error handler for includes, merge with _include()
      # tmpx is a "file" included from an upper level compile()
      my $etitle = $self->_include_error('dynamic');
      my $exists = $self->_file_exists( $tmpx );
      return $etitle . " '$tmpx' is not a file" if not $exists;
      # TODO: remove this second call somehow, reduce  to a single call
      $tmp = $self->_examine( $exists ); # re-examine
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

   my $as_is = $opt->{_sub_inc} && $opt->{_sub_inc} eq 'static';

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
   return $CODE->( @args );
}

sub _init {
   my $self = shift;
   my $d          = $self->[DELIMITERS];
   my $bogus_args = $self->[ADD_ARGS] && ! isaref($self->[ADD_ARGS]);
   my $ok_delim   = isaref( $d )      && $#{ $d } == 1;

   croak fatal('ARGS')   if     $bogus_args;
   croak fatal('DELIMS') if not $ok_delim;

   $self->[TYPE]           = '';
   $self->[COUNTER]        = 0;
   $self->[FAKER]          = $self->_output_buffer_var;
   $self->[FAKER_HASH]     = $self->_output_buffer_var('hash');
   $self->[FAKER_SELF]     = $self->_output_buffer_var('self');
   $self->[INSIDE_INCLUDE] = -1; # must be -1 not 0
   $self->[NEEDS_OBJECT]   =  0; # does the template need $self ?
   $self->[DEEP_RECURSION] =  0; # recursion detector

   if ( $self->[USER_THANDLER] ) {
      croak "user_thandler parameter must be a CODE reference"
         if ref($self->[USER_THANDLER]) ne 'CODE';
   }

   if ( $self->[INCLUDE_PATHS] ) {
      croak "include_paths parameter must be a ARRAY reference"
         if ref($self->[INCLUDE_PATHS]) ne 'ARRAY';
   }

   $self->[IO_OBJECT] = $self->connector('IO')->new( $self->[IOLAYER] );

   if ( $self->[CACHE_DIR] ) {
      my $cdir = $self->io->validate( dir => $self->[CACHE_DIR] )
                     or croak fatal( CDIR => $self->[CACHE_DIR] );
      $self->[CACHE_DIR] = $cdir;
   }

   $self->[CACHE_OBJECT] = $self->connector('Cache')->new($self);

   return;
}

sub _parser_id {
   my $self = shift;
   my $class = ref($self) || $self;
   return sprintf( "%s v%s", $class, $self->VERSION() );
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

sub _is_file {
   # safer than a simple "-e"
   my $self = shift;
   my $file = shift || return;
   return     ref $file               ? 0
         :        $file =~ RE_NONFILE ? 0
         : length $file >= 255        ? 0
         : ! -e   $file               ? 0
         :   -d _                     ? 0
         :                              1
         ;
}

sub _examine_glob {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;
   croak fatal(  NOTGLOB => $ref ) if $ref ne 'GLOB';
   croak fatal( 'NOTFH'          ) if not  fileno $TMP;
   return $self->io->slurp( $TMP );
}

sub _examine_type {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;

   return ''   => $TMP if ! $ref;
   return GLOB => $TMP if   $ref eq 'GLOB';

   if ( $ref eq 'ARRAY' ) {
      my $ftype  = shift @{ $TMP } || croak "ARRAY does not contain the type";
      my $fthing = shift @{ $TMP } || croak "ARRAY does not contain the data";
      croak "ARRAY overflowed" if @{ $TMP } > 0;
      return uc $ftype, $fthing;
   }

   croak "Unknown first argument of $ref type to compile()";
}

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
      $self->[TYPE] = 'GLOB';
   }
   else {
      if ( $type eq 'FILE' || $self->_is_file( $thing ) ) {
         $rv                = $self->io->slurp( $thing );
         $self->[TYPE]      = 'FILE';
         $self->[TYPE_FILE] = $thing;
      }
      else {
         # give it a last chance, before falling back to string
         if ( my $e = $self->_file_exists( $thing ) ) {
            $rv                = $self->io->slurp( $e );
            $self->[TYPE]      = 'FILE';
            $self->[TYPE_FILE] = $e;
         }
         else {
            $rv                = $thing;
            $self->[TYPE]      = 'STRING';
         }
      }
   }

   LOG( EXAMINE => $self->[TYPE]."; LENGTH: ".length($rv) ) if DEBUG();
   return $rv;
}

sub _compiler { shift->[SAFE] ? COMPILER_SAFE : COMPILER }

sub _wrap_compile {
   my $self   = shift;
   my $parsed = shift or croak "nothing to compile";
   LOG( CACHE_ID => $self->cache->id ) if $self->[WARN_IDS] && $self->cache->id;
   LOG( COMPILER => $self->[SAFE] ? 'Safe' : 'Normal' ) if DEBUG();
   my($CODE, $error);

   $CODE = $self->_compiler->_compile($parsed);

   if( $error = $@ ) {
      my $error2;
      if ( $self->[RESUME] ) {
         $CODE =  sub {
                     sprintf ("[%s Fatal Error] %s", $self->_parser_id, $error )
                  };
         $error2 = $@;
      }
      $error .= $error2 if $error2;
   }

   return $CODE, $error;
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

sub _parse {
   my $self     = shift;
   my $raw      = shift;
   my $map_keys = shift; # code sections are hash keys
   my $cache_id = shift;
   my $as_is    = shift; # i.e.: do not parse -> static include
   #$self->[NEEDS_OBJECT] = 0; # reset

   my $resume   = $self->[RESUME] || '';
   my $ds       = $self->[DELIMITERS][DELIM_START];
   my $de       = $self->[DELIMITERS][DELIM_END  ];
   my $faker    = $self->[INSIDE_INCLUDE] ? $self->_output_buffer_var
                                          : $self->[FAKER]
                                          ;
   my $buf_hash = $self->[FAKER_HASH];
   my $toke     = $self->connector('Tokenizer')->new( $ds, $de );
   my $code     = '';
   my $inside   = 0;

   my($mko, $mkc) = $self->_parse_mapkeys( $map_keys, $faker, $buf_hash );

   LOG( RAW => $raw ) if ( DEBUG() > 3 );

   my $handler = $self->[USER_THANDLER];

   my $w_raw = sub { ";$faker .= q~$_[0]~;" };
   my $w_cap = sub { ";$faker .= sub {" . $_[0] . "}->();"; };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $as_is;

   # fetch and walk the tree
   my($id, $str);
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $map_keys ) } ) {
      ($id, $str) = @{ $token };
      LOG( TOKEN => "$id => $str" ) if DEBUG() > 1;
      next PARSER if $id eq 'DISCARD';
      next PARSER if $id eq 'COMMENT';

      if ( $id eq 'DELIMSTART' ) { $inside++; next PARSER; }
      if ( $id eq 'DELIMEND'   ) { $inside--; next PARSER; }

      if ( $id eq 'RAW' || $id eq 'NOTADELIM' ) {
         $code .= $w_raw->($str);
      }

      elsif ( $id eq 'CODE' ) {
         $code .= $resume ? $self->_resume($str, 0, 1) : $str;
      }

      elsif ( $id eq 'CAPTURE' ) {
         $code .= $faker;
         $code .= $resume ? $self->_resume($str, RESUME_NOSTART)
                :           " .= sub { $str }->();";
      }

      elsif ( $id eq 'DYNAMIC' || $id eq 'STATIC' ) {
         $self->[NEEDS_OBJECT]++;
         $code .= $w_cap->( $self->_include($id, $str) );
      }

      elsif ( $id eq 'MAPKEY' ) {
         $code .= sprintf $mko, $mkc ? ( ($str) x 5 ) : $str;
      }

      else {
         if ( $handler ) {
            LOG( USER_THANDLER => "$id") if DEBUG;
            $code .= $handler->(
                        $self, $id ,$str, { capture => $w_cap, raw => $w_raw }
                     );
         }
         else {
            LOG( UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)")
               if DEBUG;
            $code .= $w_raw->($str);
         }
      }

   }

   $self->[FILENAME] ||= '<ANON>';

   if ( $inside ) {
      my $type = $inside > 0 ? 'opening' : 'closing';
      my $tmpl = "%d unbalanced %s delimiter(s) in template %s";
      croak sprintf( $tmpl, abs($inside), $type, $self->[FILENAME] );
   }

   return $self->_wrapper( $code, $cache_id, $faker, $map_keys );
}

sub _wrapper {
   # this'll be tricky to re-implement around a template
   my $self     = shift;
   my $code     = shift;
   my $cache_id = shift;
   my $faker    = shift;
   my $map_keys = shift;
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
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . ";return $faker;";
   $wrapper .= '}';
   # make this a capture sub if we're including
   $wrapper .= '->()' if $inside_inc;

   LOG( COMPILED => sprintf FRAGMENT_TMP, $self->_tidy($wrapper) )
      if DEBUG() > 1;
   #LOG( OUTPUT => $wrapper );
   # reset
   $self->[DEEP_RECURSION] = 0 if $self->[DEEP_RECURSION];
   return $wrapper;
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

sub _include_error {
   my $self  = shift;
   my $type  = shift;
   my $title = '[ ' . $type . ' include error ]';
   return $title;
}

sub _file_exists {
   my $self = shift;
   my $file = shift;

   return $file if $self->_is_file( $file );

   foreach my $path ( @{ $self->[INCLUDE_PATHS] } ) {
      my $test = File::Spec->catfile( $path, $file );
      return $test if $self->_is_file( $test );
   }

   return; # fail!
}

sub _include {
   my $self       = shift;
   my $type       = shift || '';
   my $file       = shift;
      $type       = lc $type;
      $file       = trim $file;
   my $is_static  = $type eq 'static';
   my $is_dynamic = $type eq 'dynamic';
   my $known      = $is_static || $is_dynamic;

   croak "Unknown include type: $type" if not $known;

   my $err    = $self->_include_error( $type );
   my $exists = $self->_file_exists( $file );
   my $interpolate;

   if ( $exists ) {
      $file        = $exists; # file path correction
      $interpolate = 0;
   }
   else {
      $interpolate = 1; # just guessing ...
   }

   if ( -d $file ) {
      $file = escape '~' => $file;
      return "q~$err '$file' is a directory~";
   }

   LOG( INCLUDE => "$type => '$file'" ) if DEBUG();

   my $text;
   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG();
      return $rv;
   }
   else {
      eval { $text = $self->io->slurp($file) };
      return "q~$err $@~" if $@;
   }

   return $self->_include_dynamic( $file, $text, $err) if $is_dynamic;
   return $self->_include_static(  $file, $text, $err);
}

sub _mini_compiler {
   # little dumb compiler for internal templates
   my $self     = shift;
   my $template = shift || croak "_mini_compiler(): missing the template";
   my $param    = shift || croak "_mini_compiler(): missing the parameters";
   my $opt      = shift || {};

   croak "_mini_compiler(): options must be a hash"    if ! ref($opt)   eq 'HASH';
   croak "_mini_compiler(): parameters must be a HASH" if ! ref($param) eq 'HASH';

   foreach my $var ( keys %{ $param } ) {
      $template =~ s[<%\Q$var\E%>][$param->{$var}]xmsg;
   }

   $template =~ s{\s+}{ }xmsg if $opt->{flatten}; # remove extra spaces
   return $template;
}

sub _internal {
   my $self = shift;
   my $id   = shift            || croak "_internal(): id is missing";
   my $rv   = $INTERNAL{ $id } || croak "_internal(): id is invalid";
   return $rv;
}

sub _interpolate {
   my $self   = shift;
   my $file   = shift;
   my $type   = shift;
   my $etitle = $self->_include_error($type);
   my $rv     = $self->_mini_compiler(
                  $self->_internal('sub_include') => {
                     OBJECT      => $self->[FAKER_SELF],
                     INCLUDE     => escape( q{'} => $file   ),
                     ERROR_TITLE => escape( q{'} => $etitle ),
                     TYPE        => $type,
                  } => {
                     flatten => 1,
                  }
               );
   return $rv;
}

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
        : $self->_include_no_monolith( static => $file )
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
      LOG( DEEP_RECURSION => $file ) if DEBUG;
      $error = escape '~' => $error;
      $self->[DEEP_RECURSION] = 1;
      $rv .= "q~$error~";
   }
   else {
      $rv .= $self->[MONOLITH]
           ? $self->_parse( $text )
           : $self->_include_no_monolith( dynamic => $file )
           ;
   }

   --$self->[INSIDE_INCLUDE]; # critical: always adjust this
   return $rv;
}

sub _resume {
   my $self    = shift;
   my $token   = shift           || return;
   my $nostart = shift           || 0;
   my $is_code = shift           || 0;
   my $resume  = $self->[RESUME] || '';
   my $start   = $nostart ? '' : $self->[FAKER];
   my $void    = $nostart ? 0  : 1; # not a self-printing block

   if ( $token && $resume && $token !~ RESUME_MY ) {
      if (
            $token !~ RESUME_CURLIES &&
            $token !~ RESUME_ELSIF   &&
            $token !~ RESUME_ELSE    &&
            $token !~ RESUME_LOOP
      ) {
         LOG( RESUME_OK => $token ) if DEBUG() > 2;
         my $rvar        = $self->_output_buffer_var('array');
         my $resume_code = RESUME_TEMPLATE;
         foreach my $replace (
            [ RVAR  => $rvar             ],
            [ TOKEN => $token            ],
            [ PID   => $self->_parser_id ],
            [ VOID  => $void             ],
         ) {
            $resume_code =~ s{ <% $replace->[0] %> }{$replace->[1]}xmsg;
         }
         return $start . $resume_code;
      }
   }

   LOG( RESUME_NOT => $token ) if DEBUG() > 2;

   return $is_code ? $token : "$start .= $token;"
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG;
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
escaped delimiters (C<< <%! %> >>), static include directives (C<< <%+ %> >>),
and dynamic include directives (C<< <%* %> >>):

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

Included files won't be parsed and included statically. To enable
parsing for the included files, use the dynamic includes:

   <%* my_other.html %>
   <%* my_other.txt  %>

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

=head3 iolayer

This option does not have any effect under perls older than C<5.8.0>.
Set this to C<utf8> (no initial colon) if your I/O is C<UTF-8>. 
Not tested with other encodings.

=head3 stack

This option enables caller stack tracing for templates. The generated
list is sent to C<warn>. So, it is possible to capture
this data with a signal handler. See L<Text::Template::Simple::Caller>
for available options.

It is also possible to send the output to the template output buffer, if you
append C<:buffer> to the type of the C<stack> option:

   $template = Text::Template::Simple->new(
      stack => 'string:buffer',
   );

C<html_comment> is the same as C<string> except that it also includes HTML
comment markers. C<text_table> needs the optional module C<Text::Table>.

This option is also available to all templates as a function named
C<stack> for individual stack dumping. See L<Text::Template::Simple::Dummy>
for more information.

=head3 monolith

Controls the behavior when using includes. If this is enabled, the template
and all it's includes will be compiled into a single document. If C<monolith>
is disabled, then the includes will be compiled individually into separate
documents.

If you need to pass the main template variables (C<my> vars) into dynamic
includes, then you need to enable this option. However, if you are using the
cache, then the included templates will not be updated automatically.

C<monolith> is disabled by default.

=head1 include_paths

An ARRAY reference. If you want to use relative file paths when
compiling/including template files, add the paths of the templates with
this parameter.

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

   $text = $template->compile('/my/templates/test.tts');

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

   open MYHANDLE, '/path/to/foo.tts' or die "Error: $!";
   $text = $template->compile(\*MYHANDLE); # RIGHT.
   $text = $template->compile( *MYHANDLE); # WRONG. Recognized as a file path
   $text = $template->compile(  MYHANDLE); # WRONG. Ditto. Will die under strict

or use the standard C<IO::File> module:

   use IO::File;
   my $fh = IO::File->new;
   $fh->open('/path/to/foo.tts', 'r') or die "Error: $!";
   $text = $template->compile($fh);

or you can use lexicals inside C<open> if you don't care about 
compatibility with older perl:

   open my $fh, '/path/to/foo.tts' or die "Error: $!";
   $text = $template->compile($fh);

Filehandles will B<not> be closed.

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

=head2 cache

Returns the L<Text::Template::Simple::Cache> object.

=head2 io

Returns the L<Text::Template::Simple::IO> object.

=head2 connector

Returns the class name of the supplied connector.

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

If disk cache is used, a template file with the "C<.tts.cache>"
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

=begin EXPERTS

How to add your own tokens into Text::Template::Simple?

   use strict;
   use Text::Template::Simple;
   use constant MYTEMP => q{ Testing: <%$ PROCESS some.tts %> };
   # first, register our handler for unknown tokens
   my $t = Text::Template::Simple->new( user_thandler => \&thandler );
   print $t->compile( MYTEMP );
   # then describe how to handle "our" commands
   sub Text::Template::Simple::Tokenizer::commands {
      my $self = shift;
      return(
         #   cmd id        callback
         [ qw/ $ DIRECTIVE trim  / ],
      );
   }
   # we can now use some black magic
   sub thandler {
      my($self, $id ,$str, $h) = @_;
      # $h is the wrapper handler. it has two handlers: capture & raw
      return $h->{raw}->( "id($id) cmd($str)" );
   }

=end EXPERTS

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

L<Apache::SimpleTemplate>, L<Text::Template>, L<Text::ScriptTemplate>,
L<Safe>, L<Opcode>.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
