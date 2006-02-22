package Text::Template::Simple::Dummy;
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.

package Text::Template::Simple::Compiler;
# Compiling any code inside the template class is 
# like exploding a bomb in a public place.
# Since the compiled code will have access to anything
# inside the compiler method (i.e. cache populator) and 
# to any package globals/lexicals (i.e. $self), they'll 
# all be accessible inside the template code...
#
# So, we explode the bomb in deep space instead ;)

sub _compile { return eval $_[1] }

package Text::Template::Simple::Compiler::Safe;
# Safe compiler. Totally experimental

sub _compile { return __PACKAGE__->_object->reval($_[1]) }

sub _object {
   if (__PACKAGE__->can('object')) {
      my $safe = __PACKAGE__->object;
      if ($safe && ref($safe) && eval {$safe->isa('Safe'); 1}) {
         return $safe;
      } else {
         warn "Safe object failed, falling back to default".($@ ? ': '.$@ : '.');
      }
   }
   require Safe;
   my $safe = Safe->new('Text::Template::Simple::Dummy');
   my @ops  = __PACKAGE__->_permit;
   $safe->permit(@ops);
   return $safe;
}

my @permit = qw(:default);
sub _permit {
   my $class = shift;
   my @list;
   if($class->can('permit')) {
      return $class->permit;
   }
   return @permit;
}

package Text::Template::Simple;
use strict;
use vars qw($VERSION $AUTOLOAD);
use constant DELIM_START => 0;
use constant DELIM_END   => 1;
use Carp qw(croak);

$VERSION = '0.3';

my %ATTR = ( # class attribute / configuration table
   FAKER        => '$OUT',                         # fake output buffer variable.
   FAKER_HASH   => '$___THIS_IS_A_LANG_HASH',      # fake language hash for map_keys templates
   DEBUG        => 0,                              # debugging is disabled by default
   CACHE_EXT    => '.tmpl.cache',                  # disk cache extension
   DELIMS       => [qw(<% %>)],                    # default delimiter pair
   MAX_FL       => 55,                             # Maximum template file name length
   CAN_FLOCK    =>  1,                             # can we use flock() ?
   DIGEST       => undef,                          # Digest class name. Will not be set, unless you use cache feature
   ID           => undef,                          # holds the current template id if cache is enabled
   N_COMPILER   => __PACKAGE__.'::Compiler',       # The compiler
   N_COMPILER_S => __PACKAGE__.'::Compiler::Safe', # Safe compiler
   N_DUMMY      => __PACKAGE__.'::Dummy',          # Dummy class
   # SHA seems to be more accurate, so we'll try them first.
   # Pure-Perl ones are slower, but they are fail-safes.
   # However, Digest::SHA::PurePerl does not work under $perl < 5.6.
   # But, Digest::Perl::MD5 seems to work under older perls (5.5.4 at least).
   __DIGEST_MODS => [qw(
                         Digest::SHA
                         Digest::SHA1
                         Digest::SHA2
                         Digest::SHA::PurePerl
                         Digest::MD5
                         MD5
                         Digest::Perl::MD5
   )],
);

my $CACHE = {}; # in-memory template cache

if($^O eq 'MSWin32') {
   require Win32;
   $ATTR{CAN_FLOCK} = 0 if Win32::IsWin95(); # we're running under dumb OS
}

# -------------------[ CLASS  METHODS ]------------------- #

sub DEBUG {
   my $thing = shift;
      $thing = shift  if defined $thing and ref $thing || $thing eq __PACKAGE__; # so that one can use: $self->DEBUG or DEBUG
      $ATTR{DEBUG} = $thing if defined $thing;
      $ATTR{DEBUG};
}

sub DIGEST {
   return $ATTR{DIGEST}->new if $ATTR{DIGEST};

   local $SIG{__DIE__};
   my $file;
   foreach my $mod (@{ $ATTR{__DIGEST_MODS} }) {
     ($file  = $mod) =~ s{::}{/}xmsog;
      $file .= '.pm';
      eval { require $file;};
      if($@) {
         warn "[FAILED    ] $mod - $file\n" if DEBUG;
         next;
      }
      $ATTR{DIGEST} = $mod;
      last;
   }

   if (not $ATTR{DIGEST}) {
      my @report = @{ $ATTR{__DIGEST_MODS} };
      my $last   = pop @report;
      croak "Can not load a digest module. Disable cache or install one of these ("
            .join(', ', @report)
            ." or $last). Last error was: $@";
   }

   warn "[DIGESTER  ] $ATTR{DIGEST}\n" if DEBUG;
   return $ATTR{DIGEST}->new;
}

# -------------------[ OBJECT METHODS ]------------------- #

sub new {
   my $class = shift;
   my %param = scalar(@_) % 2 ? () : (@_);

   my $self  = {
      delimiters => [@{ $ATTR{DELIMS} }], # default delimiters
      as_string  =>  0, # if true, resulting template will not be eval()ed
      delete_ws  =>  0, # delete whitespace-only fragments?
      faker      => '', # optionally, you can set FAKER to whatever you want
      cache      =>  0, # use cache or not
      cache_dir  => '', # will use hdd intead of memory for caching...
      strict     =>  1, # if you want toleration to un-declared vars, set this to false
      safe       =>  0, # use safe compartment?
      header     =>  0, # template header. i.e. global codes.
      add_args   => '', # will unshift template argument list. ARRAYref.
      _type      => '', # template type. will be set in _examine()
      COUNTER    =>  0,
      %param,                  # user can alter options
   };
   bless $self, $class;

   if ($self->{cache_dir}) {
      if (not -d $self->{cache_dir}) {
         croak "Cache dir $self->{cache_dir} does not exist!";
      }
   }
   if(my $add_args = $self->{add_args}) {
      unless (ref($add_args) && ref($add_args) eq 'ARRAY') {
         croak "Malformed add_args parameter! 'add_args' must be an arrayref!";
      }
   }
   my $d = $self->{delimiters};
   unless ($d && ref($d) && ref($d) eq 'ARRAY' && scalar(@{$d}) == 2) {
      croak "Malformed delimiter parameter! 'delimiters' must be a two element arrayref!";
   }
   $self;
}

sub reset_cache {
   my $self = shift;
   %{$CACHE} = ();
   if ($self->{cache} && $self->{cache_dir}) {
      local  *CACHE_DIR;
      opendir CACHE_DIR, $self->{cache_dir} or croak "Can not open cache dir ($self->{cache_dir}) for reading: $!";
      require File::Spec;
      my $ext = quotemeta $ATTR{CACHE_EXT};
      my $file;
      while (defined($file = readdir CACHE_DIR)) {
         next unless $file =~ m{$ext \z}xms;
         $file = File::Spec->catfile($self->{cache_dir}, $file);
         warn "[UNLINK    ] $file\n" if DEBUG;
         unlink $file;
      }
      closedir CACHE_DIR;
   }
}

sub dump_cache {
   my $self = shift;
   require Data::Dumper;
   my $d;
   my $disk_cache;
   if($self->{cache_dir}) {
      require File::Find;
      require File::Spec;
      $disk_cache = {}; # init
      my $ext = quotemeta $ATTR{CACHE_EXT};
      my $id;
      my($content, $ok, $_temp, $line);
      my $pattern = quotemeta '# [line 10]';
      File::Find::find(sub {
         return unless $_ =~ m{(.+?) $ext \z}xms;
         $id      = $1;
         $content = $self->_slurp(File::Spec->catfile($self->{cache_dir}, $_));
         $ok      = 0;  # reset
         $_temp   = ''; # reset
         foreach $line (split /\n/, $content) {
            if($line =~ m{$pattern}xmso) {
               $ok = 1,
               next;
            }
            next unless $ok;
            $_temp .= $line;
         }
         $disk_cache->{$id} = {
            MTIME => (stat $_)[9],
            CODE  => $_temp,
         };
      }, $self->{cache_dir});
   }
   $d = Data::Dumper->new([$disk_cache ? $disk_cache : $CACHE], ['$CACHE']);
   unless($disk_cache) {
      if($d->can('Deparse')) {
         $d->Deparse(1);
      } else {
         croak "Can not dump in-memory cache! Your version of Data::Dumper ($Data::Dumper::VERSION) does not implement the Deparse() method. Please upgrade this module!";
      }
   }
   return $d->Dump;
}

sub cache_size {
   my $self = shift;
   return 0 unless $self->{cache}; # calculate only if cache is enabled
   if($self->{cache_dir}) { # disk cache
      require File::Find;
      my $total = 0;
      my $ext   = quotemeta $ATTR{CACHE_EXT};
      File::Find::find(sub {
         return unless /$ext$/; # only calculate "our" files
         $total += (stat $_)[7];
      }, $self->{cache_dir});
      return $total;
   }
   else { # in memory cache
      local $SIG{__DIE__};
      if(eval {require Devel::Size; 1;}) {
         warn "[DEBUG     ] Devel::Size v$Devel::Size::VERSION is loaded.\n" if DEBUG;
         return Devel::Size::total_size($CACHE);
      } else {
         warn "Failed to load Devel::Size: $@" if DEBUG;
         return 0;
      }
   }
}

sub in_cache {
   my $self = shift;
   unless($self->{cache}) {
      warn "Cache is disabled!" if DEBUG;
      return;
   }
   croak "Parameters must be in 'param => value' format" if scalar(@_) % 2;
   my %opt = @_;
   my $id  = $opt{id}   ? $self->idgen($opt{id}  , 'custom')
           : $opt{data} ? $self->idgen($opt{data}          )
           :              croak "I need an 'id' or a 'data' parameter for cache check!";
   if($self->{cache_dir}) {
      require File::Spec;
      return -e File::Spec->catfile($self->{cache_dir}, $id . $ATTR{CACHE_EXT}) ? 1 : 0;
   } else {
      return exists $CACHE->{$id} ? 1 : 0;
   }
}

sub idgen { # cache id generator
   my $self   = shift;
   my $data   = shift or croak "Can't generate id without data!";
   my $custom = shift;
   return $self->_fake_idgen($data) if $custom;
   return $self->DIGEST->add($data)->hexdigest;
}

sub compile {
   my $self  = shift;
   my $tmpx  = shift or croak "No template specified!";
   my $param = shift || [];
   my $opt   = shift || {
      id       => '', # id is AUTO
      map_keys => 0,  # use normal behavior
      chkmt    => 0,  # check mtime of file template?
   };

   croak "params must be an arrayref!" unless ref($param) && ref($param) eq 'ARRAY';
   croak "opts must be a hashref!"     unless ref($opt)   && ref($opt)   eq 'HASH';

   my $tmp = $self->_examine($tmpx);
   if($opt->{chkmt}) {
      if($self->{_type} eq 'FILE') { 
         $opt->{chkmt} = (stat $tmpx)[9];
      } else {
         warn "[DISABLE MT] Disabling chkmt. Template is not a file\n" if DEBUG;
         $opt->{chkmt} = 0;
      }
   }

   warn "[COMPILE] $opt->{id}\n" if defined $opt->{id} && DEBUG;

   my($CODE, $ok);
   my $cache_id = '';
   if($self->{cache}) {
      my $method = $opt->{id};
      $cache_id  = (not $method or $method eq 'AUTO') ? $self->idgen($tmp) : $self->idgen($method, 'custom');
      if($CODE = $self->_cache_hit($cache_id, $opt->{chkmt})) {
         warn "[CACHE HIT ] $cache_id\n" if DEBUG;
         $ok = 1;
      }
   }

   if(not $ok) { # we have a cache miss; parse and compile
      warn "[CACHE MISS] $cache_id\n" if DEBUG;
      my $old_faker = $ATTR{FAKER};
      $self->_set_faker($self->{faker}) if $self->{faker}; # faker must be set before parsing begins
      $CODE = $self->_populate_cache( $cache_id, $self->_parse($tmp, $opt->{map_keys}), $opt->{chkmt} );
      $self->_set_faker($old_faker) if $self->{faker};
   }

   $ATTR{ID} = $cache_id; # if $cache_id;
   my   @args;
   push @args, @{ $self->{add_args} } if $self->{add_args};
   push @args, @{ $param };
   return $CODE->(@args);
}

sub get_id { $ATTR{ID} }

# -------------------[ PRIVATE METHODS ]------------------- #

sub _fake_idgen {
   my $self = shift;
   my $data = shift or croak "Can't generate id without data!";
   $data =~ s{[^A-Za-z_0-9]}{_}xmsg;
   my $len = length($data);
   if($len > $ATTR{MAX_FL}) { # limit file name length
      $data = substr $data, $len - $ATTR{MAX_FL}, $ATTR{MAX_FL};
   }
   return $data;
}

sub _examine {
   my $self = shift->_hasta_la_vista_baby;
   my $tmp  = shift;
   my $rv;
   if (my $ref = ref($tmp)) {
      if ($ref eq 'GLOB') {
         no strict 'refs';
         unless (defined *{$tmp}{IO}) { # We need 5.004 at least for that
            croak "This GLOB is not a filehandle!";
         }
         warn "[IS HANDLE ]\n" if DEBUG;
         # hmmm...
         #require Fcntl;
         #flock $tmp, Fcntl::LOCK_SH() if $ATTR{CAN_FLOCK};
         local $/;
         $rv = <$tmp>;
         #flock $tmp, Fcntl::LOCK_UN() if $ATTR{CAN_FLOCK};
         close $tmp; # ??? can this be a user option?
         $self->{_type} = 'GLOB';
      }
      else {
         croak "Unknown template parameter passed as $ref reference! Supported types are GLOB, PATH and STRING.";
      }
   }
   else {
      my $len = length $tmp;
      if (
          $len  <=  255              &&
          $tmp  !~  m{[\n\r<>\*]}xms &&
                -e  $tmp             &&
          not   -d  _
      ) {
         warn "[IS FILE   ] $tmp\n" if DEBUG;
         $self->{_type} = 'FILE';
         $rv = $self->_slurp($tmp);
      }
      else {
         $self->{_type} = 'STRING';
         warn "[IS STRING ] LENGTH: $len\n" if DEBUG;
         $rv = $tmp;
      }
   }
   return $rv;
}

sub _slurp {
   my $self = shift->_hasta_la_vista_baby;
   my $file = shift;
   require IO::File;
   require Fcntl;
   my $fh = IO::File->new;
   $fh->open($file, 'r') or croak "Error opening $file for reading: $!";
   flock $fh, Fcntl::LOCK_SH() if $ATTR{CAN_FLOCK};
   local $/;
   my $tmp = <$fh>;
   flock $fh, Fcntl::LOCK_UN() if $ATTR{CAN_FLOCK};
   $fh->close;
   return $tmp;
}

sub _compiler { $_[0]->{safe} ? $ATTR{N_COMPILER_S} : $ATTR{N_COMPILER} }

sub _cache_hit {
   my $self     = shift->_hasta_la_vista_baby;
   my $cache_id = shift;
   my $chkmt    = shift || 0;
   if($self->{cache_dir}) {
      require File::Spec;
      my $cache = File::Spec->catfile($self->{cache_dir}, $cache_id . $ATTR{CACHE_EXT});
      if(-e $cache && not -d _ && -f _) {
         my $disk_cache = $self->_slurp($cache);
         if($chkmt) {
            if($disk_cache =~ m,^#(\d+)#,) {
               my $mtime  = $1;
               if($mtime != $chkmt) {
                  warn "[MTIME DIFF]\tOLD: $mtime\n\t\tNEW: $chkmt\n" if DEBUG;
                  return; # i.e.: Update cache
               }
            }
         }
         my $CODE = $self->_compiler->_compile($disk_cache);
         croak "Error loading from disk cache: $@" if $@;
         warn "[FILE CACHE]\n" if DEBUG;
         return $CODE;
      }
   }
   else {
      if($chkmt) {
         my $mtime = $CACHE->{$cache_id}{MTIME} || 0;
         if($mtime != $chkmt) {
            warn "[MTIME DIFF]\tOLD: $mtime\n\t\tNEW: $chkmt\n" if DEBUG;
            return; # i.e.: Update cache
         }
      }
      warn "[MEM CACHE ]\n" if DEBUG;
      return $CACHE->{$cache_id}->{CODE};
   }
   return;
}

sub _populate_cache {
   my $self     = shift->_hasta_la_vista_baby;
   my $cache_id = shift;
   my $parsed   = shift;
   my $chkmt    = shift;
   my $CODE;
   if($self->{cache}) {
      if($self->{cache_dir}) {
         require File::Spec;
         require Fcntl;
         require IO::File;
         my $cache = File::Spec->catfile($self->{cache_dir}, $cache_id . $ATTR{CACHE_EXT});
         my $fh = IO::File->new;
         $fh->open($cache, '>') or croak "Error writing disk-cache $cache : $!";
         flock $fh, Fcntl::LOCK_EX() if $ATTR{CAN_FLOCK};
         print $fh $chkmt ? "#$chkmt#\n" : "##\n", $self->_cache_comment, $parsed; 
         flock $fh, Fcntl::LOCK_UN() if $ATTR{CAN_FLOCK};
         close $fh;
         $CODE = $self->_compiler->_compile($parsed);
      } 
      else {
         $CACHE->{$cache_id} = {CODE => undef, MTIME => 0}; # init
         $CODE = $CACHE->{$cache_id}->{CODE} = $self->_compiler->_compile($parsed);
         $CACHE->{$cache_id}->{MTIME} = $chkmt if $chkmt;
      }
   }
   else {
      $CODE = $self->_compiler->_compile($parsed); # cache is disabled
   }

   if($@) {
      my $cid = $cache_id ? $cache_id : 'N/A';
      my $p   = $parsed;
         $p   =~ s{;}{;\n}xmsg; # new lines makes it easy to debug
      croak sprintf $self->_compile_error_tmp, $cid, $@, $parsed, $p;
   }
   $self->{COUNTER}++;
   return $CODE;
}

sub _compile_error_tmp {
return <<'COMPILE_ERROR_TMP';
Error compiling code fragment (cache id: %s):

%s
-------------------------------
PARSED CODE (without \n added):
-------------------------------

%s

-------------------------------
PARSED CODE    (with \n added):
-------------------------------

%s
COMPILE_ERROR_TMP
}

sub _cache_comment {
return sprintf <<'DISK_CACHE_COMMENT', __PACKAGE__, $VERSION, scalar localtime time;
# !!!   W A R N I N G      W A R N I N G      W A R N I N G   !!!
# This file is automatically generated by %s v%s on %s.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
#
#
#
# [line 10]
DISK_CACHE_COMMENT
}

sub _parse {
   my $self      = shift->_hasta_la_vista_baby;
   my $tmp       = shift;
   my $map_keys  = shift; # code sections are hash keys
   my $finit     = ''; # map_keys init code
   if ($map_keys && $map_keys eq 'init') {
      $finit = q~ || ''~;
   }
   my $is_code   = 0; # we are inside a code section
   my $is_open   = 0; # if true: quote was not closed inside the parser
   my $is_fake   = 0; # fake hash is open
   my $qq        = ';'.$ATTR{FAKER}.' .= qq~'; # double quote open tag
   my $q         = ';'.$ATTR{FAKER}.' .= q~';  # single quote open tag
   my $qc        = '~;';                 # quote close tag
   my $fo        = '%s .= %s->{';        # fake hash open
   my $fc        = "}$finit;";           # fake hash close
   my $fstart    = '';                   # fake hash start
   my $fragment  = '';                   # will be the code to compile
      $fstart    = sprintf($fo, $ATTR{FAKER}, $ATTR{FAKER_HASH}) if $map_keys;
   warn "[PARSING   ]\n" if DEBUG;
   my $ds = $self->{delimiters}[DELIM_START];
   my $de = $self->{delimiters}[DELIM_END  ];
   PARSER: foreach my $token ($self->_tokenize($tmp)) {
      if ($token eq $ds) { ++$is_code;                                   next PARSER; }
      if ($token eq $de) { --$is_code; $fragment .= ';' unless $is_fake; next PARSER; }
      if($is_code) {
         if ($is_open ) { $fragment .= $qc;     --$is_open; }
         if ($map_keys) { $fragment .= $fstart; ++$is_fake; }
      }
      else {
         if (not $is_open) {
            if($is_fake) {
               --$is_fake;
               $fragment .= $fc;
            }
            $fragment .= $q;
            ++$is_open;
         }
      }
      # check if this is a <%=$foo%>
      if ($token =~ m{\A (?:\s+|)=(.+?)(?:;+|) \z}xmso) {
         # A statement can not have a comment at the end.
         # This is do-able with a "\n", but it'll also break
         # line numbers in templates
         $fragment .= sprintf "%s .= sub {%s}->();", $ATTR{FAKER}, $1;
         warn "[CASE '='  ] state: $is_code; open $is_open; match $1\n" if DEBUG;
         next PARSER;
      }
      $token     =~ s{\~}{\\\~}sog unless $is_code; # tilde is a private character (see $qq above)
      $fragment .= $token;
   }
   $fragment .= $qc if $is_open;
   $fragment .= $fc if $is_fake;
   warn "[CASE 'END'] state: $is_code; open: $is_open\n" if DEBUG;
   croak "Unbalanced delimiter in template!" if $is_code;
   my $code_start;
   $code_start  = 'package '.$ATTR{N_DUMMY}.';';
   $code_start .= 'use strict;' if $self->{strict};
   $code_start .= 'sub { ';
   $code_start .= $self->{header}.';' if $self->{header};
   $code_start .= "my $ATTR{FAKER};";
   $code_start .= qq~my $ATTR{FAKER_HASH} = {\@_};~ if $map_keys;
   $fragment    = $code_start.$fragment.";return $ATTR{FAKER};}";
   warn "\n\n#FRAGMENT\n$fragment\n#/FRAGMENT\n" if DEBUG > 1;
   return $fragment;
}

sub _tokenize {
   my $self = shift->_hasta_la_vista_baby;
   my $tmp  = shift;
   my $ds   = quotemeta $self->{delimiters}[DELIM_START];
   my $de   = quotemeta $self->{delimiters}[DELIM_END  ];
   my @parse;
   foreach my $token (split /($ds)/, $tmp) {
      push @parse, split /($de)/, $token;
   }
   return @parse;
}

sub _set_faker {
   my $self = shift->_hasta_la_vista_baby;
   my $fake = shift or return;

   if($fake =~ m{[^\$a-zA-Z_0-9]} || # can not be non-alphanumeric
      $fake =~ m{^[0-9]}          || # can not start with number
      $fake !~ m{^\$}                # must start with a dollar
      ) {
      warn "Bogus fake scalar '$fake'! Falling back to default value!" if DEBUG; # warn or die?
      return;
   }

   $ATTR{FAKER} = $fake;
}

sub _hasta_la_vista_baby {
   caller(1) eq __PACKAGE__ or croak +(caller 1)[3]."() is a private method!";
   $_[0];
}

sub AUTOLOAD {
   my $self = shift;
   my $class = ref($self) || __PACKAGE__;
  (my $name = $AUTOLOAD) =~ s{.*:}{};
   croak qq~Unknown method name $name called via $class object~;
}

sub DESTROY  {}

1;

__END__

=head1 NAME

Text::Template::Simple - Simple text template engine.

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

Template syntax is very simple. There are two kind of delimiters;
code blocks (<%%>) and self-printing blocks (<%=%>):

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

=head2 Template parameters

You can fetch parameters (passed to compile) in the usual perl way:

   <%
      my $foo = shift;
      my %bar = @_;
   %>
   Baz is <%=$bar{baz}%>

=head2 Special Variables

There is a special variable inside all templates. You must not
define a variable with the same name inside templates or alter
it's name before L</compile>.

=head3 Output Buffer Variable

Default name is C<$OUT>. Output will be collected inside this
variable and then returned. Works transparent, and you don't 
have to touch it manually.

=head1 METHODS

=head2 new

Creates a new template object and can take several parameters.

=head3 delimiters

Must be an array ref containing the two delimiter values: 
the opening delimiter and the closing delimiter:

   $template = Text::Template::Simple->new(
      delimiters => ['<?perl', '?>'],
   );

Default values are C<E<lt>%> and C<E<gt>%>. 

=head3 faker

Compiled templates will have two special variables. The output
is buffered inside a hidden variable named C<$OUT>. You can alter the 
name of this variable if you pass a C<faker> parameter:

   $template = Text::Template::Simple->new(
      faker => '$___this_does_not_exist',
   );

=head3 cache

Pass this with a true value if you want the cache feature.
In-memory cache will be used unless you also pass a L</cache_dir>
parameter.

=head3 cache_dir

If you want disk-based cache, set this parameter to a valid
directory path. You must also set L</cache> to a true value.

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

See L<Safe> and especially L<Opcode> for opcode lists and other details.

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
   $text = $template->compile( *MYHANDLE); # WRONG. Will be recognized as a file path
   $text = $template->compile(  MYHANDLE); # WRONG. Ditto. And this'll die under strict

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

Early versions of C<Data::Dumper> does not have a C<Deparse>
method, so you may need to upgrade your C<Data::Dumper> if
you want to use this method.

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

   if($template->in_cache(id => 'e369853df766fa44e1ed0ff613f563bd') {
      print "ok!";
   }

or

   if($template->in_cache(data => q~Foo is <%=$bar%>~) {
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
the program more faster under persistent environments. But the 
overall speed depends on your environment.

=head2 Interface Change

This module was initially a C<Text::Template> sub-class.
But beginning with version C<0.3> it no longer has any 
relations with C<Text::Template> and the interface is 
slightly changed. So, if you've liked and used an earlier 
version, I'm sorry about this change. I figured out that 
C<Text::Template> is not suitable for my needs and instead 
choosed a new path for my code.

=head1 SEE ALSO

This module's parser is based on L<Apache::SimpleTemplate>. 
Also see L<Text::Template> for a similar functionality.
L<HTML::Template::Compiled> has a similar approach
for compiled templates. There is another similar module
named L<Text-ScriptTemplate>. Also see L<Safe> and
L<Opcode>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.7 or, 
at your option, any later version of Perl 5 you may have available.

=cut
