package Text::Template::Simple;
use strict;
use vars qw[$VERSION];
use Text::Template;

$VERSION = '0.1';

sub new {
   my $class  = shift;
   my %option = scalar @_ % 2 ? () : (@_);
   foreach my $k (keys %option) { # delimiters; global; dummy; reset_dummy
      $option{lc $k} =  $option{$k};
   }
   my $self = {};
   bless $self, $class;
   # check for bad values
   foreach my $key (keys %option) {
      if ($key eq 'delimiters' && (!ref $option{$key} || ref $option{$key} ne 'ARRAY' || $#{$option{$key}} < 1)) {
         die("The parameter 'delimiters' must be an ARRAYREF with two values!");
      }
      if ($key eq 'globals' && !(ref $option{$key} && ref $option{$key} eq 'HASH')) {
         die("Global parameters must be passed as a HASHREF!");
      }
      $self->{$key} = $option{$key}; # dummy; define_type: vars|our;
   }
   $self->{delimiters}   = ['<%', '%>']     unless $self->{delimiters};
   $self->{globals}      = ''               unless $self->{globals};
   $self->{dummy}        = $class.'::Dummy' unless $self->{dummy};
   # auto construct
   if($] < 5.006) {
      $self->{define_type}  = 'use strict;use vars qw[%s];';
      $self->{symbol_delim} = ' ';
   } else {
      $self->{define_type}  = 'use strict;our(%s);';
      $self->{symbol_delim} = ', ';
   }
   return $self;
}

sub compile {
   my $self   = shift;
   my $class  = ref $self;
   my $source = shift || '';
   my $params = shift || '';
   if ($params && (!$params || !ref($params) || ref $params ne 'HASH')) {
      die("Unvalid parameter value! It must be a HASHREF!");
   }
   my $template = Text::Template->new(TYPE       => 'STRING', 
                                      SOURCE     => $source,
                                      DELIMITERS => $self->{delimiters},
                                      ) or die("Couldn't construct the page template: $Text::Template::ERROR");
   my $prepend = $params ? sprintf($self->{define_type}, join($self->{symbol_delim}, $self->prepare_symbols($params))) : '';
   my $text = $template->fill_in(PACKAGE => $self->{dummy},
                                 HASH    => $params ? $params : {},
                    ($prepend ? (PREPEND => $prepend) : ()),
              ) or die("Couldn't fill in template: $Text::Template::ERROR");
   if ($self->{reset_dummy}) {
      eval 'undef %'.$self->{dummy}.'::;'; # reset symbol table
   }
   return $text;
}

sub prepare_symbols {
   my $self   = shift;
   my $params = shift;
   return if !$params || !ref $params || ref $params ne 'HASH';
   my(@globals, $prefix, $ref);
   if($self->{globals}) { # define global template elements
      foreach(keys %{$self->{globals}}) {
         $params->{$_} = $self->{globals}->{$_};
      }
   }
   # setup global variables and initialize any undef values
   foreach my $key (keys %{ $params }) {
      if ($ref = ref $params->{$key}) {
         if ($ref eq 'HASH') {
            foreach my $p (keys %{ $params->{$key} }) {
               next if ref $params->{$key}->{$p};
               unless(defined $params->{$key}->{$p}) {
                  $params->{$key}->{$p} = '';
               }
            }
            $prefix = '%';
         }
         elsif ($ref eq 'ARRAY') {
            foreach my $index (0..$#{ $params->{$key} }) {
               next if ref $params->{$key}->[$index];
               unless(defined $params->{$key}->[$index]) {
                  $params->{$key}->[$index] = '';
               }
            }
            $prefix = '@';
         }
         elsif ($ref eq 'GLOB') {
            die "GLOBs are not supported!";
         }
         else { # SCALAR/CODE/OBJ
            unless (ref $params->{$key}) {
               unless(defined $params->{$key}) {
                  $params->{$key} = '';
               }
            }
            $prefix = '$';
         }
      }
      else { # SCALAR
         unless (ref $params->{$key}) {
            unless(defined $params->{$key}) {
               $params->{$key} = '';
            }
         }
         $prefix = '$';
      }
      push @globals, $prefix . $key;
   }
   return @globals;
}

package Text::Template::Simple::Dummy;

1;

__END__

=head1 NAME

Text::Template::Simple - A simple template class mainly for web applications.

=head1 SYNOPSIS

   use Text::Template::Simple;

   my $template = Text::Template::Simple->new(
      delimiters => ['{', '}'],
      globals => {
         foo  => 'bar'  , # define $foo
         bar  => ['baz'], # define @bar
         blah => {        # define %blah
            key => 'value',
         },
      },
      dummy => "MY::Dummy::Class::To::Fill::In::Templates",
      # reset_dummy => 1, # reset dummy class' symbol table explicitly
    );

   my $result = $template->compile(
                  'Hello {$foo}. Key is: {$blah{key}} and Your name is {$name}.',
                  {
                     name => 'Burak',
                  });
   print $result;

=head1 DESCRIPTION

This module provides a simple and high level access to C<Text::Template>
modules interface. It also adds a C<PREPEND> parameter to enable C<strict>
mode and define the variables before using them. If your perl version is 
smaller than C<5.6>; the C<vars> pragma, and if it is greater; C<our> 
function will be used to define variables in the template. Main purpose 
of this module is to setup that variable definiton code and itialize all
variables if any on them has the value C<undef>.

=head1 METHODS

=head2 new

The object constructor. Takes several parameters:

=head3 delimiters

The default delimiter set is: C<E<lt>% %E<gt>>. You can pass you own
delimiters as an arrayref:

   Text::Template::Simple->new(
      delimiters => ['{', '}'],
   )

=head3 global

You can define variables that are globally accessible by all templates. 

Example:

   $globals = {
         foo  => 'bar'  , # define $foo
         bar  => ['baz'], # define @bar
         blah => {        # define %blah
            key => 'value',
         },
   };

   Text::Template::Simple->new(
      globals => $globals,
   )

=head3 dummy

This must be a dummy package/class name. The module will compile 
the template into this class. If you don't set it, the default class 
C<Text::Template::Simple::Dummy> will be used.

=head2 compile TEMPLATE, PARAMS

Compiles the template into its final form. Takes two paramters. First 
parameter is the raw template code as a string and second is the 
parameters you can set. C<PARAMS> must be a C<HASHREF>.

   my $result = $template->compile('Your name is {$name}.',
                  {
                     name => 'Burak', # set $name
                  });

=head1 BUGS

=over 4

=item Complete interface of C<Text::Template> is B<not> supported.

=item Parameter names can B<not> start with minus

Example: C<-dummy> or C<-Dummy> is unvalid. Use C<dummy> or C<Dummy>
or C<DUMMY> etc...

=item Only single string data is accepted as a template text

Filehandles and any other things are not supported. You must supply a 
single text parameter as the template code.

=item C<SAFE>, C<BROKEN_ARG> and friends are not supported.

Many paramaters to C<Text::Template> is not supported.

=back

There may be many more... Please report if you find any bugs.

=head1 SEE ALSO

L<Text::Template>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
