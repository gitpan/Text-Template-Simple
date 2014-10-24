package Text::Template::Simple::Constants;
use strict;
use warnings;
use vars qw($VERSION $OID $DID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.83';

use constant MINUS_ONE           => -1;

# object fields
BEGIN { $OID = MINUS_ONE } # init object field id counter
use constant DELIMITERS          => ++$OID;
use constant AS_STRING           => ++$OID;
use constant DELETE_WS           => ++$OID;
use constant FAKER               => ++$OID;
use constant FAKER_HASH          => ++$OID;
use constant FAKER_SELF          => ++$OID;
use constant FAKER_WARN          => ++$OID;
use constant MONOLITH            => ++$OID;
use constant CACHE               => ++$OID;
use constant CACHE_DIR           => ++$OID;
use constant CACHE_OBJECT        => ++$OID;
use constant IO_OBJECT           => ++$OID;
use constant STRICT              => ++$OID;
use constant SAFE                => ++$OID;
use constant HEADER              => ++$OID;
use constant ADD_ARGS            => ++$OID;
use constant CAPTURE_WARNINGS    => ++$OID;
use constant WARN_IDS            => ++$OID;
use constant TYPE                => ++$OID;
use constant TYPE_FILE           => ++$OID;
use constant COUNTER             => ++$OID;
use constant COUNTER_INCLUDE     => ++$OID;
use constant INSIDE_INCLUDE      => ++$OID;
use constant NEEDS_OBJECT        => ++$OID;
use constant CID                 => ++$OID;
use constant FILENAME            => ++$OID;
use constant IOLAYER             => ++$OID;
use constant STACK               => ++$OID;
use constant USER_THANDLER       => ++$OID;
use constant DEEP_RECURSION      => ++$OID;
use constant INCLUDE_PATHS       => ++$OID;
use constant PRE_CHOMP           => ++$OID;
use constant POST_CHOMP          => ++$OID;
use constant VERBOSE_ERRORS      => ++$OID;
use constant TAINT_MODE          => ++$OID;
use constant MAXOBJFIELD         =>   $OID; # number of the last object field

# token type ids
BEGIN { $DID = 0 }
use constant T_DELIMSTART        => ++$DID;
use constant T_DELIMEND          => ++$DID;
use constant T_DISCARD           => ++$DID;
use constant T_COMMENT           => ++$DID;
use constant T_RAW               => ++$DID;
use constant T_NOTADELIM         => ++$DID;
use constant T_CODE              => ++$DID;
use constant T_CAPTURE           => ++$DID;
use constant T_DYNAMIC           => ++$DID;
use constant T_STATIC            => ++$DID;
use constant T_MAPKEY            => ++$DID;
use constant T_COMMAND           => ++$DID;
use constant T_MAXID             =>   $DID;

# settings
use constant MAX_RECURSION       => 50; # recursion limit for dynamic includes
use constant PARENT              => ( __PACKAGE__ =~ m{ (.+?) ::Constants }xms );
use constant IS_WINDOWS          => $^O eq 'MSWin32' || $^O eq 'MSWin64';
use constant DELIM_START         => 0; # field id
use constant DELIM_END           => 1; # field id
use constant RE_NONFILE          => qr{ [ \n \r < > \* \? ] }xmso;
use constant RE_DUMP_ERROR       => qr{Can\'t \s locate \s object \s method \s "first" \s via \s package \s "B::SVOP"}xms;
use constant COMPILER            => PARENT.'::Compiler'; # The compiler
use constant COMPILER_SAFE       => COMPILER.'::Safe';   # Safe compiler
use constant DUMMY_CLASS         => PARENT.'::Dummy';    # Dummy class
use constant MAX_FL              => 120;                 # Maximum file name length
use constant CACHE_EXT           => '.tts.cache';        # disk cache extension
use constant STAT_SIZE           => 7;                   # for stat()
use constant STAT_MTIME          => 9;                   # for stat()
use constant DELIMS              => qw( <% %> );         # default delimiter pair
use constant NEW_PERL            => $] >= 5.008;         # for I/O layer
use constant IS_FLOCK            => IS_WINDOWS ? ( Win32::IsWin95() ? 0 : 1 ) : 1;

use constant CHOMP_NONE          => 0x000000;
use constant COLLAPSE_NONE       => 0x000000;
use constant CHOMP_ALL           => 0x000002;
use constant CHOMP_LEFT          => 0x000004;
use constant CHOMP_RIGHT         => 0x000008;
use constant COLLAPSE_LEFT       => 0x000010;
use constant COLLAPSE_RIGHT      => 0x000020;
use constant COLLAPSE_ALL        => 0x000040;

use constant TAINT_CHECK_NORMAL  => 0x000000;
use constant TAINT_CHECK_ALL     => 0x000002;
use constant TAINT_CHECK_WINDOWS => 0x000004;
use constant TAINT_CHECK_FH_READ => 0x000008;

# first level directives
use constant DIR_CAPTURE         => q{=};
use constant DIR_DYNAMIC         => q{*};
use constant DIR_STATIC          => q{+};
use constant DIR_NOTADELIM       => q{!};
use constant DIR_COMMENT         => q{#};
use constant DIR_COMMAND         => q{|};
# second level directives
use constant DIR_CHOMP           => q{-};
use constant DIR_COLLAPSE        => q{~};
use constant DIR_CHOMP_NONE      => q{^};

# token related indexes
use constant TOKEN_STR           =>  0;
use constant TOKEN_ID            =>  1;
use constant TOKEN_CHOMP         =>  2;
use constant TOKEN_TRIGGER       =>  3;

use constant TOKEN_CHOMP_NEXT    =>  0; # sub-key for TOKEN_CHOMP
use constant TOKEN_CHOMP_PREV    =>  1; # sub-key for TOKEN_CHOMP

use constant LAST_TOKEN          => -1;
use constant PREVIOUS_TOKEN      => -2;

use constant CACHE_PARENT        => 0; # object id
use constant CACHE_FMODE         => 0600;

use constant EMPTY_STRING        => q{};

use constant FMODE_GO_WRITABLE   => 022;
use constant FMODE_GO_READABLE   => 066;
use constant FTYPE_MASK          => 07777;

use constant MAX_PATH_LENGTH     => 255;
use constant DEVEL_SIZE_VERSION  => 0.72;

use constant DEBUG_LEVEL_NORMAL  => 1;
use constant DEBUG_LEVEL_VERBOSE => 2;
use constant DEBUG_LEVEL_INSANE  => 3;


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

use constant RE_PIPE_SPLIT   => qr/ \| (?:\s+)? (NAME|PARAM|FILTER|SHARE) : /xms;
use constant RE_FILTER_SPLIT => qr/ \, (?:\s+)? /xms;
use constant RE_INVALID_CID  => qr{[^A-Za-z_0-9]}xms;

use constant DISK_CACHE_MARKER => q{# This file is automatically generated by }
                               .  PARENT
                               ;

use base qw( Exporter );

BEGIN {

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
                        RE_INVALID_CID
                        STAT_SIZE
                        MAX_RECURSION
                        CACHE_FMODE
                        CACHE_PARENT
                        MINUS_ONE
                        EMPTY_STRING
                        MAX_PATH_LENGTH
                        DEVEL_SIZE_VERSION
                     )],
      fmode     =>   [qw(
                        FMODE_GO_WRITABLE
                        FMODE_GO_READABLE
                        FTYPE_MASK
                     )],
      debug     =>   [qw(
                        DEBUG_LEVEL_NORMAL
                        DEBUG_LEVEL_VERBOSE
                        DEBUG_LEVEL_INSANE
                     )],
   );

   @EXPORT_OK        = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   @EXPORT           = @EXPORT_OK;

}

1;

__END__

=head1 NAME

Text::Template::Simple::Constants - Constants

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.83> of C<Text::Template::Simple::Constants>
released on C<9 February 2011>.

Constants for Text::Template::Simple.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.1 or, 
at your option, any later version of Perl 5 you may have available.

=cut
