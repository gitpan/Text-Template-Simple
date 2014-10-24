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

use Carp qw( croak );

$VERSION = '0.54_14';

sub stack {
   my $self    = shift;
   my $opt     = shift || {};
   die "Parameters to stack() must be a HASH" if ref($opt) ne 'HASH';
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

1;

__END__

=head1 NAME

Text::Template::Simple::Caller - Caller stack tracer

=head1 SYNOPSIS

   use strict;
   use Text::Template::Simple::Caller;
   x();
   sub x {  y() }
   sub y {  z() }
   sub z { print Text::Template::Simple::Caller->stack }

=head1 DESCRIPTION

Caller stack tracer for Text::Template::Simple. This module is not used
directly inside templates. You must use the global template function
instead. See L<Text::Template::Simple::Dummy> for usage from the templates.

=head1 METHODS

=head2 stack

Class method. Accepts parameters as a single hashref:

   my $dump = Text::Template::Simple::Caller->stack(\%opts);

=head3 frame

Integer. Defines how many call frames to go back. Default is zero (full list).

=head3 type

Defines the dump type. Available options are:

=over 4

=item string

A simple text dump.

=item html_comment

Same as string, but the output wrapped with HTML comment codes:

   <!-- [DUMP] -->

=item html_table

Returns the dump as a HTML table.

=item text_table

Uses the optional module C<Text::Table> to format the dump.

=back

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
