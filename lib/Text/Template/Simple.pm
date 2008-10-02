package Text::Template::Simple;
use strict;
use vars qw($VERSION);

$VERSION = '0.54_17';

use Carp qw( croak );
use File::Spec;

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
   delimiters     => [ DELIMS ], # default delimiters
   cache          =>  0,    # use cache or not
   cache_dir      => '',    # will use hdd intead of memory for caching...
   strict         =>  1,    # set to false for toleration to un-declared vars
   safe           =>  0,    # use safe compartment?
   header         =>  0,    # template header. i.e. global codes.
   add_args       => '',    # will unshift template argument list. ARRAYref.
   warn_ids       =>  0,    # warn template ids?
   iolayer        => '',    # I/O layer for filehandles
   stack          => '',    # dump caller stack?
   user_thandler  => undef, # user token handler callback
   monolith       =>  0,    # use monolithic template & cache ?
   include_paths  => [],    # list of template dirs
   pre_chomp      => CHOMP_NONE,
   post_chomp     => CHOMP_NONE,
   # TODO: Consider removing this
   resume         =>  0,    # resume on error?
);

my @EXPORT_OK = qw( tts );

sub import {
   my $class = shift;
   my $caller = caller;
   my @args   = @_ or return;
   my %ok     = map { $_, $_ } @EXPORT_OK;

   foreach my $name ( @args ) {
      croak "$name isn't a valid import parameter for $class" if not $ok{$name};
      no strict qw( refs );
      croak "$name is not defined in $class"      if not defined &{ $name   };
      my $target = $caller . '::' . $name;
      croak "$name is already defined in $caller" if     defined &{ $target };
      *{ $target } = \&{ $name }; # install
   }

   return;
}

sub tts {
   my @args = @_;
   croak "Nothing to compile!" if ! @args;
   my @new  = ref $args[0] eq 'HASH' ? @{ shift(@args) } : ();
   return __PACKAGE__->new( @new )->compile( @args );
}

sub new {
   my $class = shift;
   my %param = scalar(@_) % 2 ? () : (@_);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   LOG( CONSTRUCT => $self->_class_id . " @ ".(scalar localtime time) )
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

sub _file_exists {
   # TODO: pass INCLUDE_PATHS to ::IO to move this there
   my $self = shift;
   my $file = shift;

   return $file if $self->io->is_file( $file );

   foreach my $path ( @{ $self->[INCLUDE_PATHS] } ) {
      my $test = File::Spec->catfile( $path, $file );
      return $test if $self->io->is_file( $test );
   }

   return; # fail!
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

=over 4

=item *

Code Blocks: C<< <% %> >>

=item *

Self-printing Blocks: C<< <%= %> >>

=item *

Escaped Delimiters: C<< <%! %> >>

=item *

Static Include Directives: C<< <%+ %> >>

=item *

Dynamic include directives C<< <%* %> >>

=item *

Comment Directives: C<< <%# %> >>

=back

A simple example:

   <%
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   %>
   Element is <%= $x %>
   <% } %>

Do not directly use print() statements, since they'll break the code.
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

Interpolation is also supported with both kind of includes, so the following
is valid code:

   <%+ "/path/to/" . $txt    %>
   <%* "/path/to/" . $myfile %>

=head2 Chomping

Chomping is the removal of whitespace before and after your directives. This
can be useful if you're generating plain text (instead of HTML which'll ignore
spaces most of the time). You can either remove all space or replace multiple
whitespace with a single space (collapse). Chomping can be enabled per directive
or globally via options to the constructor. See L</pre_chomp> and L</post_chomp>
options to L</new> to globally enable chomping.

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

=head2 ACCESSING TEMPLATE NAMES

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

=head3 include_paths

An ARRAY reference. If you want to use relative file paths when
compiling/including template files, add the paths of the templates with
this parameter.

=head3 pre_chomp

   use Text::Template::Simple::Constants qw( :chomp );
   $pre = CHOMP_NONE; # no chomp
   $pre = CHOMP_ALL;  # remove all whitespace
   $pre = COLLAPSE_ALL; # replace all ws with a single space
   $template = Text::Template::Simple->new(
      pre_chomp => $pre,
   );

=head3 post_chomp

   use Text::Template::Simple::Constants qw( :chomp );
   $post = CHOMP_NONE; # no chomp
   $post = CHOMP_ALL;  # remove all whitespace
   $post = COLLAPSE_ALL; # replace all ws with a single space
   $template = Text::Template::Simple->new(
      post_chomp => $post,
   );

=head2 compile DATA [, FILL_IN_PARAM, OPTIONS]

Compiles the template you have passed and manages template cache,
if you've enabled cache feature. Then it returns the compiled template.
Accepts three different types of data as the first parameter; 
a reference to a filehandle (C<GLOB>), a string or a file path 
(path to the template file).

=head3 First parameter (DATA)

The first parameter can take four different values; a filehandle,
a string, a file path or explicit type definition via an ARRAY reference.
Distinguishing filehandles are easy, since
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

=head4 Explicit Types

Pass an arrayref containing the type and the parameter to disable guessing
and forcing the type:

   $text = $template->compile( [ FILE   => '/path/to/my.tts'] );
   $text = $template->compile( [ GLOB   => \*MYHANDLE] );
   $text = $template->compile( [ STRING => 'I am running under <%= $] %>'] );

Type can be one of these: C<FILE>, C<GLOB>, C<STRING>.

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

=head1 FUNCTIONS

=head2 tts [ NEW_ARGS, ] COMPILE_ARGS

This function is a wrapper around the L<Text::Template::Simple> object. It
creates it's own temporary object behind the scenes and can be used for
quick Perl one-liners for example. Using this function other than testing is
not recommended.

C<NEW_ARGS> is optional and must be a hashref containing the parameters to
L</new>. C<COMPILE_ARGS> is a list and everything it contains will be passed
to the L</compile> method.

It is possible to import this function to your namespace:

   use Text::Template::Simple qw( tts );
   print tts("<%= scalar localtime time %>");
   print tts( { strict => 1 }, "<%= scalar localtime time %>");

=head1 EXAMPLES

TODO

=head1 ERROR HANDLING

You may need to C<eval> your code blocks to trap exceptions. Some recoverable
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
