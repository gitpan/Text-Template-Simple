package Text::Template::Simple::Constants;
use strict;
use vars qw($VERSION $OID $DID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.62_15';

# object fields
BEGIN { $OID = -1 } # init object field id counter
use constant DELIMITERS       => ++$OID;
use constant AS_STRING        => ++$OID;
use constant DELETE_WS        => ++$OID;
use constant FAKER            => ++$OID;
use constant FAKER_HASH       => ++$OID;
use constant FAKER_SELF       => ++$OID;
use constant MONOLITH         => ++$OID;
use constant CACHE            => ++$OID;
use constant CACHE_DIR        => ++$OID;
use constant CACHE_OBJECT     => ++$OID;
use constant IO_OBJECT        => ++$OID;
use constant STRICT           => ++$OID;
use constant SAFE             => ++$OID;
use constant HEADER           => ++$OID;
use constant ADD_ARGS         => ++$OID;
use constant WARN_IDS         => ++$OID;
use constant TYPE             => ++$OID;
use constant TYPE_FILE        => ++$OID;
use constant COUNTER          => ++$OID;
use constant COUNTER_INCLUDE  => ++$OID;
use constant INSIDE_INCLUDE   => ++$OID;
use constant NEEDS_OBJECT     => ++$OID;
use constant CID              => ++$OID;
use constant FILENAME         => ++$OID;
use constant RESUME           => ++$OID;
use constant IOLAYER          => ++$OID;
use constant STACK            => ++$OID;
use constant USER_THANDLER    => ++$OID;
use constant DEEP_RECURSION   => ++$OID;
use constant INCLUDE_PATHS    => ++$OID;
use constant PRE_CHOMP        => ++$OID;
use constant POST_CHOMP       => ++$OID;
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
use constant RESUME_NOSTART   => 1;                   # bool
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
# This file is automatically generated by %s on %s.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
TEMPLATE_CONSTANT

use constant DISK_CACHE_MARKER => q{# This file is automatically generated by }
                               .  PARENT
                               ;

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
                        TYPE
                        TYPE_FILE
                        COUNTER
                        COUNTER_INCLUDE
                        INSIDE_INCLUDE
                        NEEDS_OBJECT
                        CID
                        FILENAME
                        RESUME
                        IOLAYER
                        STACK
                        USER_THANDLER
                        DEEP_RECURSION
                        INCLUDE_PATHS
                        PRE_CHOMP
                        POST_CHOMP
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
      etc       =>   [qw(
                        DIGEST_MODS
                        STAT_MTIME
                        RE_DUMP_ERROR
                        RE_PIPE_SPLIT
                        RE_FILTER_SPLIT
                        RE_NONFILE
                        STAT_SIZE
                        MAX_RECURSION
                     )],
   );

   @EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   @EXPORT           = @EXPORT_OK;

}

BEGIN { require Exporter; }

1;

__END__

=head1 NAME

Text::Template::Simple::Constants - Constants

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.62_15> of C<Text::Template::Simple::Constants>
released on C<21 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

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
