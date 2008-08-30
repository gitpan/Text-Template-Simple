#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Text::Template::Simple;
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

can_ok( 'Text::Template::Simple',
        qw/
            new
            cache
            io
            compile
            connector
            _init
            _parser_id
            _output_buffer_var
            _examine
            _compiler
            _wrap_compile
            _tidy
            _parse
            _add_stack
            _include
            _resume
            DESTROY
            _fix_uncuddled
        /
    );
can_ok( 'Text::Template::Simple::Constants',
        qw/
            IS_FLOCK
            NEW_PERL
            IS_WINDOWS
            COMPILER
            COMPILER_SAFE
            DUMMY_CLASS
            MAX_FL
            CACHE_EXT
            PARENT
            COMPILE_ERROR_TMP
            FRAGMENT_TMP
            DISK_CACHE_COMMENT
            DISK_CACHE_MARKER
            MAP_KEYS_CHECK
            MAP_KEYS_INIT
            MAP_KEYS_DEFAULT
            DELIM_START
            DELIM_END
            DELIMS
            DELIMITERS
            AS_STRING
            DELETE_WS
            FAKER
            FAKER_HASH
            CACHE
            CACHE_DIR
            CACHE_OBJECT
            IO_OBJECT
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
            USER_THANDLER
            MAXOBJFIELD
            RESUME_NOSTART
            RESUME_MY
            RESUME_CURLIES
            RESUME_ELSIF
            RESUME_ELSE
            RESUME_LOOP
            RESUME_TEMPLATE
            DIGEST_MODS
            STAT_MTIME
            RE_DUMP_ERROR
            STAT_SIZE
            RE_NONFILE
        /
    );
can_ok( 'Text::Template::Simple::Dummy',
        qw/
            stack
        /
    );
can_ok( 'Text::Template::Simple::Compiler',
        qw/
            _compile
        /
    );
can_ok( 'Text::Template::Simple::Compiler::Safe',
        qw/
            _compile
            _object
            _permit
        /
    );
can_ok( 'Text::Template::Simple::Caller',
        qw/
            PACKAGE
            FILENAME
            LINE
            SUBROUTINE
            HASARGS
            WANTARRAY
            EVALTEXT
            IS_REQUIRE
            HINTS
            BITMASK
            stack
            _string
            _html_comment
            _html_table
            _html_table_blank_check
            _text_table
        /
    );
can_ok( 'Text::Template::Simple::Tokenizer',
        qw/
            CMD_CHAR
            CMD_ID
            CMD_CB
            TOKEN_ID
            TOKEN_STR
            LAST_TOKEN
            ID_DS
            ID_DE
            ID_FU
            SUBSTR_OFFSET
            SUBSTR_LENGTH
            new
            tokenize
            _token_code
            _user_commands
            tilde
            quote
            trim
        /
    );
can_ok( 'Text::Template::Simple::Util',
        qw/
            binary_mode
            isaref
            ishref
            fatal 
            DEBUG
            DIGEST
            LOG
            _is_parent_object
        /
    );
can_ok( 'Text::Template::Simple::Cache::ID',
        qw/
            new
            get
            set
            generate
            _custom
        /
    );
can_ok( 'Text::Template::Simple::Cache',
        qw/
            new
            id
            type
            reset
            dumper
            _dump_ids
            _dump_structure
            _dump_disk_cache
            size
            has
            hit
            populate
            DESTROY
        /
    );
can_ok( 'Text::Template::Simple::IO',
        qw/
            new
            validate
            layer
            slurp
            DESTROY
        /
    );
