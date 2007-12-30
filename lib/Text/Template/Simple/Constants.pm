package Text::Template::Simple::Constants;
use strict;
use vars qw($VERSION $OID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.50';

use constant PARENT         => 'Text::Template::Simple';
use constant IS_WINDOWS     => $^O eq 'MSWin32' || $^O eq 'MSWin64';
use constant DELIM_START    => 0;
use constant DELIM_END      => 1;
use constant RE_NONFILE     => qr{ [ \n \r < > \* \? ] }xmso;
use constant RE_DUMP_ERROR  => qr{Can\'t locate object method "first" via package "B::SVOP"};
use constant RESUME_NOSTART => 1;                         # bool
use constant COMPILER       => PARENT.'::Compiler';       # The compiler
use constant COMPILER_SAFE  => PARENT.'::Compiler::Safe'; # Safe compiler
use constant DUMMY_CLASS    => PARENT.'::Dummy';          # Dummy class
use constant MAX_FL         => 80;                        # Maximum file name length
use constant CACHE_EXT      => '.tmpl.cache';             # disk cache extension
use constant STAT_SIZE      => 7;                         # for stat()
use constant STAT_MTIME     => 9;                         # for stat()
use constant DELIMS         => qw( <% %> );               # default delimiter pair
use constant NEW_PERL       => $] >= 5.008;               # for I/O layer

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

use constant FRAGMENT_TMP      => <<'TEMPLATE_CONSTANT';

# BEGIN TIDIED FRAGMENT

%s

# END TIDIED FRAGMENT
TEMPLATE_CONSTANT

use constant COMPILE_ERROR_TMP => <<'TEMPLATE_CONSTANT';
Error compiling code fragment (cache id: %s):

%s
-------------------------------
PARSED CODE (VERBATIM):
-------------------------------

%s

-------------------------------
PARSED CODE    (tidied):
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

use constant RESUME_TEMPLATE => sub {
   my $tmp = q~
         .= sub {
                  local $SIG{__DIE__};
                  my <%RVAR%> = [];
                  push @{ <%RVAR%> }, eval { <%TOKEN%> };
                  return qq([<%PID%> Fatal Error] $@) if $@;
                  return "" if(<%VOID%>);
                  return <%RVAR%>->[0] if @{<%RVAR%>} == 1;
                  return +(@{<%RVAR%>});
         }->();
   ~;
   $tmp =~ s/\n//xmsg;
   $tmp =~ s/\s{2,}/ /xmsg;
   return $tmp;
}->();

use constant RESUME_MY => qr{
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

use constant RESUME_CURLIES => qr{
   \A (?:\s+|) (?:[\{\}]) (?:\s+|) \z
}xms;

use constant RESUME_ELSIF => qr{
   \A (?:\s+|) (?:\}) (?:\s+|) (?:else|elsif)
}xms;

use constant RESUME_ELSE => qr{
   \A (?:\s+|) \} (?:\s+|)
   else (?:\s+|) (?:\{) (?:\s+|) \z
}xms;

use constant RESUME_LOOP => qr{ (?:next|last|continue|redo) }xms;

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

use Exporter ();

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
                        COMPILE_ERROR_TMP
                        FRAGMENT_TMP
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
      resume    =>   [qw(
                        RESUME_NOSTART
                        RESUME_MY
                        RESUME_CURLIES
                        RESUME_ELSIF
                        RESUME_ELSE
                        RESUME_LOOP
                        RESUME_TEMPLATE
                     )],
      etc       =>   [qw(
                        DIGEST_MODS
                        STAT_MTIME
                        RE_DUMP_ERROR
                        STAT_SIZE
                        RE_NONFILE
                     )],
   );

   @EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   @EXPORT           = @EXPORT_OK;

}

1;

__END__

=head1 NAME

Text::Template::Simple::Constants - Constants for Text::Template::Simple

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

Constants for Text::Template::Simple.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
