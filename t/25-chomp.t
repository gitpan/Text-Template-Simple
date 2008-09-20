#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );

use Text::Template::Simple;
use Text::Template::Simple::Constants qw( :chomp );
my(%pool, %tts, %valid);

# token directive takes precedence over global
# <%- -%> -> chomp
# <%^ ^%> -> no chomp
# <%~ ~%> -> collapse

foreach my $oid ( sort keys %pool ) {
    my $t = $pool{ $oid };
    ok( defined($t), "$oid object is defined OK" );
    ok( $t->isa('Text::Template::Simple'), "$oid object is-a Text::Template::Simple" );

    foreach my $tid ( sort keys %tts ) {
        my $data   = $tts{$tid};
        my $rv     = $t->compile( $data->[0] );
        my $expect = $data->[1]{$oid};

        ok( defined($rv)  , "Got compiled result from $oid -> $tid"        );
        ok( $rv eq $expect, "$oid -> $tid compiled ok: '$rv' == '$expect'" );
    }

}

# wrong naming below! swap col <-> none

BEGIN {
    sub rv {
        my $id = shift;
        return $valid{ $id } || die "$id is invalid";
    }

    %valid = (
           'none_chomp_code' => {
                                  'col_all' => ' ',
                                  'all_all' => ' ',
                                  'all_col' => '  ',
                                  'col_none' => ' ',
                                  'none_none' => ' ',
                                  'all_none' => ' ',
                                  'none_col' => '  ',
                                  'none_all' => ' ',
                                  'col_col' => '  '
                                },
           'col_none_comment' => {
                                   'col_all' => ' ',
                                   'all_all' => ' ',
                                   'all_col' => ' ',
                                   'col_none' => ' ',
                                   'none_none' => ' ',
                                   'all_none' => ' ',
                                   'none_col' => ' ',
                                   'none_all' => ' ',
                                   'col_col' => ' '
                                 },
           'col_no_capture' => {
                                 'col_all' => '42',
                                 'all_all' => '42',
                                 'all_col' => '42 ',
                                 'col_none' => ' 42 ',
                                 'none_none' => ' 42 ',
                                 'all_none' => ' 42 ',
                                 'none_col' => '42 ',
                                 'none_all' => '42',
                                 'col_col' => '42 '
                               },
           'chomp_chomp_capture' => {
                                      'col_all' => ' 42',
                                      'all_all' => '42',
                                      'all_col' => '42 ',
                                      'col_none' => ' 42',
                                      'none_none' => '42',
                                      'all_none' => '42',
                                      'none_col' => '42 ',
                                      'none_all' => '42',
                                      'col_col' => ' 42 '
                                    },
           'none_no_comment' => {
                                  'col_all' => ' ',
                                  'all_all' => ' ',
                                  'all_col' => '  ',
                                  'col_none' => ' ',
                                  'none_none' => ' ',
                                  'all_none' => ' ',
                                  'none_col' => '  ',
                                  'none_all' => ' ',
                                  'col_col' => '  '
                                },
           'chomp_no_comment' => {
                                   'col_all' => ' ',
                                   'all_all' => '',
                                   'all_col' => ' ',
                                   'col_none' => ' ',
                                   'none_none' => '',
                                   'all_none' => '',
                                   'none_col' => ' ',
                                   'none_all' => '',
                                   'col_col' => '  '
                                 },
           'col_none_capture' => {
                                   'col_all' => '42 ',
                                   'all_all' => '42 ',
                                   'all_col' => '42 ',
                                   'col_none' => '42 ',
                                   'none_none' => '42 ',
                                   'all_none' => '42 ',
                                   'none_col' => '42 ',
                                   'none_all' => '42 ',
                                   'col_col' => '42 '
                                 },
           'none_none_comment' => {
                                    'col_all' => '  ',
                                    'all_all' => '  ',
                                    'all_col' => '  ',
                                    'col_none' => '  ',
                                    'none_none' => '  ',
                                    'all_none' => '  ',
                                    'none_col' => '  ',
                                    'none_all' => '  ',
                                    'col_col' => '  '
                                  },
           'no_no_capture' => {
                                'col_all' => ' 42',
                                'all_all' => '42',
                                'all_col' => '42 ',
                                'col_none' => ' 42',
                                'none_none' => ' 42 ',
                                'all_none' => '42',
                                'none_col' => '42 ',
                                'none_all' => '42',
                                'col_col' => ' 42 '
                              },
           'chomp_none_comment' => {
                                     'col_all' => '  ',
                                     'all_all' => ' ',
                                     'all_col' => ' ',
                                     'col_none' => '  ',
                                     'none_none' => ' ',
                                     'all_none' => ' ',
                                     'none_col' => ' ',
                                     'none_all' => ' ',
                                     'col_col' => '  '
                                   },
           'col_chomp_comment' => {
                                    'col_all' => '',
                                    'all_all' => '',
                                    'all_col' => ' ',
                                    'col_none' => '',
                                    'none_none' => '',
                                    'all_none' => '',
                                    'none_col' => ' ',
                                    'none_all' => '',
                                    'col_col' => ' '
                                  },
           'no_col_code' => {
                              'col_all' => ' ',
                              'all_all' => '',
                              'all_col' => '',
                              'col_none' => ' ',
                              'none_none' => '  ',
                              'all_none' => '',
                              'none_col' => '  ',
                              'none_all' => '  ',
                              'col_col' => ' '
                            },
           'no_chomp_comment' => {
                                   'col_all' => ' ',
                                   'all_all' => '',
                                   'all_col' => ' ',
                                   'col_none' => ' ',
                                   'none_none' => '',
                                   'all_none' => '',
                                   'none_col' => ' ',
                                   'none_all' => '',
                                   'col_col' => '  '
                                 },
           'chomp_none_capture' => {
                                     'col_all' => ' 42 ',
                                     'all_all' => '42 ',
                                     'all_col' => '42 ',
                                     'col_none' => ' 42 ',
                                     'none_none' => '42 ',
                                     'all_none' => '42 ',
                                     'none_col' => '42 ',
                                     'none_all' => '42 ',
                                     'col_col' => ' 42 '
                                   },
           'chomp_col_comment' => {
                                    'col_all' => ' ',
                                    'all_all' => '',
                                    'all_col' => '',
                                    'col_none' => ' ',
                                    'none_none' => '',
                                    'all_none' => '',
                                    'none_col' => '',
                                    'none_all' => '',
                                    'col_col' => ' '
                                  },
           'no_none_comment' => {
                                  'col_all' => '  ',
                                  'all_all' => ' ',
                                  'all_col' => ' ',
                                  'col_none' => '  ',
                                  'none_none' => ' ',
                                  'all_none' => ' ',
                                  'none_col' => ' ',
                                  'none_all' => ' ',
                                  'col_col' => '  '
                                },
           'no_no_code' => {
                             'col_all' => ' ',
                             'all_all' => '',
                             'all_col' => ' ',
                             'col_none' => ' ',
                             'none_none' => '  ',
                             'all_none' => '',
                             'none_col' => ' ',
                             'none_all' => '',
                             'col_col' => '  '
                           },
           'no_no_comment' => {
                                'col_all' => ' ',
                                'all_all' => '',
                                'all_col' => ' ',
                                'col_none' => ' ',
                                'none_none' => '  ',
                                'all_none' => '',
                                'none_col' => ' ',
                                'none_all' => '',
                                'col_col' => '  '
                              },
           'none_none_capture' => {
                                    'col_all' => ' 42 ',
                                    'all_all' => ' 42 ',
                                    'all_col' => ' 42 ',
                                    'col_none' => ' 42 ',
                                    'none_none' => ' 42 ',
                                    'all_none' => ' 42 ',
                                    'none_col' => ' 42 ',
                                    'none_all' => ' 42 ',
                                    'col_col' => ' 42 '
                                  },
           'col_col_capture' => {
                                  'col_all' => ' 42 ',
                                  'all_all' => ' 42 ',
                                  'all_col' => ' 42 ',
                                  'col_none' => ' 42 ',
                                  'none_none' => ' 42 ',
                                  'all_none' => ' 42 ',
                                  'none_col' => ' 42 ',
                                  'none_all' => ' 42 ',
                                  'col_col' => ' 42 '
                                },
           'no_chomp_capture' => {
                                   'col_all' => ' 42',
                                   'all_all' => '42',
                                   'all_col' => '42 ',
                                   'col_none' => ' 42',
                                   'none_none' => '42',
                                   'all_none' => '42',
                                   'none_col' => '42 ',
                                   'none_all' => '42',
                                   'col_col' => ' 42 '
                                 },
           'chomp_col_capture' => {
                                    'col_all' => ' 42',
                                    'all_all' => '42',
                                    'all_col' => '42',
                                    'col_none' => ' 42',
                                    'none_none' => '42',
                                    'all_none' => '42',
                                    'none_col' => '42',
                                    'none_all' => '42',
                                    'col_col' => ' 42'
                                  },
           'none_chomp_comment' => {
                                     'col_all' => ' ',
                                     'all_all' => ' ',
                                     'all_col' => '  ',
                                     'col_none' => ' ',
                                     'none_none' => ' ',
                                     'all_none' => ' ',
                                     'none_col' => '  ',
                                     'none_all' => ' ',
                                     'col_col' => '  '
                                   },
           'col_col_comment' => {
                                  'col_all' => '  ',
                                  'all_all' => '  ',
                                  'all_col' => '  ',
                                  'col_none' => '  ',
                                  'none_none' => '  ',
                                  'all_none' => '  ',
                                  'none_col' => '  ',
                                  'none_all' => '  ',
                                  'col_col' => '  '
                                },
           'col_chomp_capture' => {
                                    'col_all' => '42',
                                    'all_all' => '42',
                                    'all_col' => '42 ',
                                    'col_none' => '42',
                                    'none_none' => '42',
                                    'all_none' => '42',
                                    'none_col' => '42 ',
                                    'none_all' => '42',
                                    'col_col' => '42 '
                                  },
           'chomp_no_code' => {
                                'col_all' => ' ',
                                'all_all' => '',
                                'all_col' => ' ',
                                'col_none' => ' ',
                                'none_none' => '',
                                'all_none' => '',
                                'none_col' => ' ',
                                'none_all' => '',
                                'col_col' => '  '
                              },
           'no_chomp_code' => {
                                'col_all' => ' ',
                                'all_all' => '',
                                'all_col' => ' ',
                                'col_none' => ' ',
                                'none_none' => '',
                                'all_none' => '',
                                'none_col' => ' ',
                                'none_all' => '',
                                'col_col' => '  '
                              },
           'none_none_code' => {
                                 'col_all' => '  ',
                                 'all_all' => '  ',
                                 'all_col' => '  ',
                                 'col_none' => '  ',
                                 'none_none' => '  ',
                                 'all_none' => '  ',
                                 'none_col' => '  ',
                                 'none_all' => '  ',
                                 'col_col' => '  '
                               },
           'chomp_no_capture' => {
                                   'col_all' => ' 42',
                                   'all_all' => '42',
                                   'all_col' => '42 ',
                                   'col_none' => ' 42',
                                   'none_none' => '42',
                                   'all_none' => '42',
                                   'none_col' => '42 ',
                                   'none_all' => '42',
                                   'col_col' => ' 42 '
                                 },
           'chomp_none_code' => {
                                  'col_all' => '  ',
                                  'all_all' => ' ',
                                  'all_col' => ' ',
                                  'col_none' => '  ',
                                  'none_none' => ' ',
                                  'all_none' => ' ',
                                  'none_col' => ' ',
                                  'none_all' => ' ',
                                  'col_col' => '  '
                                },
           'no_none_code' => {
                               'col_all' => '  ',
                               'all_all' => ' ',
                               'all_col' => ' ',
                               'col_none' => '  ',
                               'none_none' => ' ',
                               'all_none' => ' ',
                               'none_col' => ' ',
                               'none_all' => ' ',
                               'col_col' => '  '
                             },
           'chomp_col_code' => {
                                 'col_all' => ' ',
                                 'all_all' => '',
                                 'all_col' => '',
                                 'col_none' => ' ',
                                 'none_none' => '',
                                 'all_none' => '',
                                 'none_col' => '',
                                 'none_all' => '',
                                 'col_col' => ' '
                               },
           'none_no_code' => {
                               'col_all' => ' ',
                               'all_all' => ' ',
                               'all_col' => '  ',
                               'col_none' => ' ',
                               'none_none' => ' ',
                               'all_none' => ' ',
                               'none_col' => '  ',
                               'none_all' => ' ',
                               'col_col' => '  '
                             },
           'col_chomp_code' => {
                                 'col_all' => '',
                                 'all_all' => '',
                                 'all_col' => ' ',
                                 'col_none' => '',
                                 'none_none' => '',
                                 'all_none' => '',
                                 'none_col' => ' ',
                                 'none_all' => '',
                                 'col_col' => ' '
                               },
           'chomp_chomp_comment' => {
                                      'col_all' => ' ',
                                      'all_all' => '',
                                      'all_col' => ' ',
                                      'col_none' => ' ',
                                      'none_none' => '',
                                      'all_none' => '',
                                      'none_col' => ' ',
                                      'none_all' => '',
                                      'col_col' => '  '
                                    },
           'col_none_code' => {
                                'col_all' => ' ',
                                'all_all' => ' ',
                                'all_col' => ' ',
                                'col_none' => ' ',
                                'none_none' => ' ',
                                'all_none' => ' ',
                                'none_col' => ' ',
                                'none_all' => ' ',
                                'col_col' => ' '
                              },
           'col_no_comment' => {
                                 'col_all' => '',
                                 'all_all' => '',
                                 'all_col' => ' ',
                                 'col_none' => '  ',
                                 'none_none' => '  ',
                                 'all_none' => '  ',
                                 'none_col' => ' ',
                                 'none_all' => '',
                                 'col_col' => ' '
                               },
           'none_col_capture' => {
                                   'col_all' => ' 42',
                                   'all_all' => ' 42',
                                   'all_col' => ' 42',
                                   'col_none' => ' 42',
                                   'none_none' => ' 42',
                                   'all_none' => ' 42',
                                   'none_col' => ' 42',
                                   'none_all' => ' 42',
                                   'col_col' => ' 42'
                                 },
           'none_chomp_capture' => {
                                     'col_all' => ' 42',
                                     'all_all' => ' 42',
                                     'all_col' => ' 42 ',
                                     'col_none' => ' 42',
                                     'none_none' => ' 42',
                                     'all_none' => ' 42',
                                     'none_col' => ' 42 ',
                                     'none_all' => ' 42',
                                     'col_col' => ' 42 '
                                   },
           'no_col_comment' => {
                                 'col_all' => ' ',
                                 'all_all' => '',
                                 'all_col' => '',
                                 'col_none' => ' ',
                                 'none_none' => '  ',
                                 'all_none' => '',
                                 'none_col' => '  ',
                                 'none_all' => '  ',
                                 'col_col' => ' '
                               },
           'none_no_capture' => {
                                  'col_all' => ' 42',
                                  'all_all' => ' 42',
                                  'all_col' => ' 42 ',
                                  'col_none' => ' 42',
                                  'none_none' => ' 42',
                                  'all_none' => ' 42',
                                  'none_col' => ' 42 ',
                                  'none_all' => ' 42',
                                  'col_col' => ' 42 '
                                },
           'none_col_code' => {
                                'col_all' => ' ',
                                'all_all' => ' ',
                                'all_col' => ' ',
                                'col_none' => ' ',
                                'none_none' => ' ',
                                'all_none' => ' ',
                                'none_col' => ' ',
                                'none_all' => ' ',
                                'col_col' => ' '
                              },
           'chomp_chomp_code' => {
                                   'col_all' => ' ',
                                   'all_all' => '',
                                   'all_col' => ' ',
                                   'col_none' => ' ',
                                   'none_none' => '',
                                   'all_none' => '',
                                   'none_col' => ' ',
                                   'none_all' => '',
                                   'col_col' => '  '
                                 },
           'col_col_code' => {
                               'col_all' => '  ',
                               'all_all' => '  ',
                               'all_col' => '  ',
                               'col_none' => '  ',
                               'none_none' => '  ',
                               'all_none' => '  ',
                               'none_col' => '  ',
                               'none_all' => '  ',
                               'col_col' => '  '
                             },
           'no_col_capture' => {
                                 'col_all' => ' 42',
                                 'all_all' => '42',
                                 'all_col' => '42',
                                 'col_none' => ' 42',
                                 'none_none' => ' 42 ',
                                 'all_none' => '42',
                                 'none_col' => ' 42 ',
                                 'none_all' => ' 42 ',
                                 'col_col' => ' 42'
                               },
           'no_none_capture' => {
                                  'col_all' => ' 42 ',
                                  'all_all' => '42 ',
                                  'all_col' => '42 ',
                                  'col_none' => ' 42 ',
                                  'none_none' => '42 ',
                                  'all_none' => '42 ',
                                  'none_col' => '42 ',
                                  'none_all' => '42 ',
                                  'col_col' => ' 42 '
                                },
           'col_no_code' => {
                              'col_all' => '',
                              'all_all' => '',
                              'all_col' => ' ',
                              'col_none' => '  ',
                              'none_none' => '  ',
                              'all_none' => '  ',
                              'none_col' => ' ',
                              'none_all' => '',
                              'col_col' => ' '
                            },
           'none_col_comment' => {
                                   'col_all' => ' ',
                                   'all_all' => ' ',
                                   'all_col' => ' ',
                                   'col_none' => ' ',
                                   'none_none' => ' ',
                                   'all_none' => ' ',
                                   'none_col' => ' ',
                                   'none_all' => ' ',
                                   'col_col' => ' '
                                 }
    );

    %pool = (
        none_none => Text::Template::Simple->new(
            pre_chomp  => CHOMP_NONE,
            post_chomp => CHOMP_NONE,
        ),
        all_all => Text::Template::Simple->new(
            pre_chomp  => CHOMP_ALL,
            post_chomp => CHOMP_ALL,
        ),
        col_col => Text::Template::Simple->new(
            pre_chomp  => CHOMP_COLLAPSE,
            post_chomp => CHOMP_COLLAPSE,
        ),
        all_col => Text::Template::Simple->new(
            pre_chomp  => CHOMP_ALL,
            post_chomp => CHOMP_COLLAPSE,
        ),
        col_all => Text::Template::Simple->new(
            pre_chomp  => CHOMP_COLLAPSE,
            post_chomp => CHOMP_ALL,
        ),
        none_col => Text::Template::Simple->new(
            pre_chomp  => CHOMP_NONE,
            post_chomp => CHOMP_COLLAPSE,
        ),
        col_none => Text::Template::Simple->new(
            pre_chomp  => CHOMP_COLLAPSE,
            post_chomp => CHOMP_NONE,
        ),
        none_all => Text::Template::Simple->new(
            pre_chomp  => CHOMP_NONE,
            post_chomp => CHOMP_ALL,
        ),
        all_none => Text::Template::Simple->new(
            pre_chomp  => CHOMP_ALL,
            post_chomp => CHOMP_NONE,
        ),
    );

    %tts = (
        # nothing
        no_no_code          => [ q( <%  my $x = 42   %> ), rv('no_no_code') ],
        no_no_capture       => [ q( <%=    42        %> ), rv('no_no_capture') ],
        no_no_comment       => [ q( <%# nonsense     %> ), rv('no_no_comment') ],

        # chomp
        chomp_chomp_code    => [ q( <%-  my $x = 42 -%> ), rv('chomp_chomp_code') ],
        chomp_chomp_capture => [ q( <%=-    42      -%> ), rv('chomp_chomp_capture') ],
        chomp_chomp_comment => [ q( <%#- nonsense   -%> ), rv('chomp_chomp_comment') ],

        chomp_no_code       => [ q( <%-  my $x = 42  %> ), rv('chomp_no_code') ],
        chomp_no_capture    => [ q( <%=-    42       %> ), rv('chomp_no_capture') ],
        chomp_no_comment    => [ q( <%#- nonsense    %> ), rv('chomp_no_comment') ],

        no_chomp_code       => [ q( <%  my $x = 42  -%> ), rv('no_chomp_code') ],
        no_chomp_capture    => [ q( <%=    42       -%> ), rv('no_chomp_capture') ],
        no_chomp_comment    => [ q( <%# nonsense    -%> ), rv('no_chomp_comment') ],

        # no chomp
        none_none_code      => [ q( <%~  my $x = 42 ~%> ), rv('none_none_code') ],
        none_none_capture   => [ q( <%=~    42      ~%> ), rv('none_none_capture') ],
        none_none_comment   => [ q( <%#~ nonsense   ~%> ), rv('none_none_comment') ],

        none_no_code        => [ q( <%~  my $x = 42  %> ), rv('none_no_code') ],
        none_no_capture     => [ q( <%=~    42       %> ), rv('none_no_capture') ],
        none_no_comment     => [ q( <%#~ nonsense    %> ), rv('none_no_comment') ],

        no_none_code        => [ q( <%  my $x = 42  ~%> ), rv('no_none_code') ],
        no_none_capture     => [ q( <%=    42       ~%> ), rv('no_none_capture') ],
        no_none_comment     => [ q( <%# nonsense    ~%> ), rv('no_none_comment') ],

        # collapse
        col_col_code        => [ q( <%^  my $x = 42 ^%> ), rv('col_col_code') ],
        col_col_capture     => [ q( <%=^    42      ^%> ), rv('col_col_capture') ],
        col_col_comment     => [ q( <%#^ nonsense   ^%> ), rv('col_col_comment') ],

        col_no_code         => [ q( <%^  my $x = 42  %> ), rv('col_no_code') ],
        col_no_capture      => [ q( <%=^    42       %> ), rv('col_no_capture') ],
        col_no_comment      => [ q( <%#^ nonsense    %> ), rv('col_no_comment') ],

        no_col_code         => [ q( <%  my $x = 42  ^%> ), rv('no_col_code') ],
        no_col_capture      => [ q( <%=    42       ^%> ), rv('no_col_capture') ],
        no_col_comment      => [ q( <%# nonsense    ^%> ), rv('no_col_comment') ],

        # phase 2

        # none - chomp
        none_chomp_code     => [ q( <%~ my $x = 42   -%> ), rv('none_chomp_code') ],
        none_chomp_capture  => [ q( <%=~    42       -%> ), rv('none_chomp_capture') ],
        none_chomp_comment  => [ q( <%#~ nonsense    -%> ), rv('none_chomp_comment') ],

        chomp_none_code     => [ q( <%-  my $x = 42  ~%> ), rv('chomp_none_code') ],
        chomp_none_capture  => [ q( <%=-    42       ~%> ), rv('chomp_none_capture') ],
        chomp_none_comment  => [ q( <%#- nonsense    ~%> ), rv('chomp_none_comment') ],

        # none - collapse
        none_col_code       => [ q( <%~  my $x = 42  ^%> ), rv('none_col_code') ],
        none_col_capture    => [ q( <%=~    42       ^%> ), rv('none_col_capture') ],
        none_col_comment    => [ q( <%#~ nonsense    ^%> ), rv('none_col_comment') ],

        col_none_code       => [ q( <%^  my $x = 42  ~%> ), rv('col_none_code') ],
        col_none_capture    => [ q( <%=^    42       ~%> ), rv('col_none_capture') ],
        col_none_comment    => [ q( <%#^ nonsense    ~%> ), rv('col_none_comment') ],

        # collapse - chomp
        col_chomp_code      => [ q( <%^  my $x = 42  -%> ), rv('col_chomp_code') ],
        col_chomp_capture   => [ q( <%=^    42       -%> ), rv('col_chomp_capture') ],
        col_chomp_comment   => [ q( <%#^ nonsense    -%> ), rv('col_chomp_comment') ],

        chomp_col_code      => [ q( <%-  my $x = 42  ^%> ), rv('chomp_col_code') ],
        chomp_col_capture   => [ q( <%=-    42       ^%> ), rv('chomp_col_capture') ],
        chomp_col_comment   => [ q( <%#- nonsense    ^%> ), rv('chomp_col_comment') ],
    );
}

__END__
