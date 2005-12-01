package Text::Template::Simple::Sub;
use strict;
use vars qw(@ISA $EXTEND $DEBUG);
use Text::Template;

@ISA    = qw(Text::Template);
$DEBUG  = 0; # print debug lines if enabled
$EXTEND = 0; # to extend or not

SCOPE: { # subclassing Text::Template is a little tough job
   no strict 'refs';
   *{$_} = \&{'Text::Template::'.$_} foreach (qw[_param _install_hash _default_broken]);
}

# we need to override the fill_in method to implement template loops
sub fill_in {
  my $fi_self = shift;
  unless ($EXTEND) {
     return $fi_self->SUPER::fill_in(@_);
  }
  my %fi_a = @_;

  unless ($fi_self->{TYPE} eq 'PREPARSED') {
    my $delims = _param('delimiters', %fi_a);
    my @delim_arg = (defined $delims ? ($delims) : ());
    $fi_self->compile(@delim_arg)
      or return undef;
  }

  my $fi_varhash = _param('hash', %fi_a);
  my $fi_package = _param('package', %fi_a) ;
  my $fi_broken  = 
    _param('broken', %fi_a)  || $fi_self->{BROKEN} || \&_default_broken;
  my $fi_broken_arg = _param('broken_arg', %fi_a) || [];
  my $fi_safe = _param('safe', %fi_a);
  my $fi_ofh = _param('output', %fi_a);
  my $fi_eval_package;
  my $fi_scrub_package = 0;
  my $fi_filename = _param('filename') || $fi_self->{FILENAME} || 'template';

  my $fi_prepend = _param('prepend', %fi_a);
  unless (defined $fi_prepend) {
    $fi_prepend = $fi_self->prepend_text;
  }

  if (defined $fi_safe) {
    $fi_eval_package = 'main';
  } elsif (defined $fi_package) {
    $fi_eval_package = $fi_package;
  } elsif (defined $fi_varhash) {
    $fi_eval_package = _gensym();
    $fi_scrub_package = 1;
  } else {
    $fi_eval_package = caller;
  }

  my $fi_install_package;
  if (defined $fi_varhash) {
    if (defined $fi_package) {
      $fi_install_package = $fi_package;
    } elsif (defined $fi_safe) {
      $fi_install_package = $fi_safe->root;
    } else {
      $fi_install_package = $fi_eval_package; # The gensymmed one
    }
    _install_hash($fi_varhash => $fi_install_package);
  }

  if (defined $fi_package && defined $fi_safe) {
    no strict 'refs';
    # Big fat magic here: Fix it so that the user-specified package
    # is the default one available in the safe compartment.
    *{$fi_safe->root . '::'} = \%{$fi_package . '::'};   # LOD
  }

  my $fi_r = '';
  my $fi_item;
  my $loop_depth = 0;
  my $loop_text  = '';
  foreach $fi_item (@{$fi_self->{SOURCE}}) {
    my ($fi_type, $fi_text, $fi_lineno) = @$fi_item;
    if ($fi_type eq 'TEXT') {
      if ($loop_depth) {
        (my $tmp = $fi_text) =~ s,\~,\\\~,sg; # ~ is now a special char.
         chomp $tmp;      # remove extra \n caused by a loop construct
         $tmp =~ s/^\n//; # ditto. but we may need a bare \n inside the template... 
         unless ($tmp) {
            warn "\$fi_text is empty!" if $DEBUG;
            next;
         }
         $loop_text .= "\$OUT .= qq~".$tmp."~;";
         next;
      }
      if ($fi_ofh) {
	print $fi_ofh $fi_text;
      } else {
	$fi_r .= $fi_text;
      }
    } elsif ($fi_type eq 'PROG') {
     (my $tft = $fi_text) =~ s/\s//sg;
      my $fi_lcomment = "#line $fi_lineno $fi_filename";
      my $fi_progtext = 
        "package $fi_eval_package; $fi_prepend;\n$fi_lcomment\n$fi_text";
      if ($tft =~ m/^(if|unless|while|for|foreach)\(.+?\){$/) {
         $loop_depth++;
         warn "loop_depth++" if $DEBUG;
      } elsif ($tft =~ m/^(while|for|foreach)(.+?)\(.+?\){$/) {
         $loop_depth++;
         warn "loop_depth++ (loop with param)" if $DEBUG;
      } elsif ($tft eq '}') {
         $loop_depth--;
         $loop_text .= $tft unless $loop_depth;
         warn "loop_depth--" if $DEBUG;
      } elsif ($tft =~ m/^}else{$/) {
         warn "empty loop element else" if $DEBUG;
      } elsif ($tft =~ m/^}elsif\(.+?\){$/) {
         warn "empty loop element elsif" if $DEBUG;
      } else {
         # do nothing ?
      }
      # if we use ";" and $loop_depth, then it'll be "if($foo){;"
      $fi_progtext .= ';' unless $loop_depth;
      if ($loop_depth) {
         if(not $loop_text) {
            $loop_text = $fi_progtext;
         } else {
            $loop_text .= $fi_text;
         }
         next;
      }
      if ($DEBUG && $loop_text) {
        warn "loop(\n$loop_text\n);";
      }
      my $fi_res;
      my $fi_eval_err = '';
      if ($fi_safe) {
        $fi_safe->reval(q{undef $OUT});
	$fi_res = $loop_text ? $fi_safe->reval($loop_text) : $fi_safe->reval($fi_progtext);
	$fi_eval_err = $@;
	my $OUT = $fi_safe->reval('$OUT');
	$fi_res = $OUT if defined $OUT;
      } else {
	my $OUT;
	$fi_res = $loop_text ? eval($loop_text) : eval($fi_progtext); # eval true ? foo : bar seems to fail
	$fi_eval_err = $@;
	$fi_res = $OUT if defined $OUT;
      }

      $loop_text = ''; # reset

      # If the value of the filled-in text really was undef,
      # change it to an explicit empty string to avoid undefined
      # value warnings later.
      $fi_res = '' unless defined $fi_res;

      if ($fi_eval_err) {
	$fi_res = $fi_broken->(text => $fi_text,
			       error => $fi_eval_err,
			       lineno => $fi_lineno,
			       arg => $fi_broken_arg,
			       );
	if (defined $fi_res) {
	  if (defined $fi_ofh) {
	    print $fi_ofh $fi_res;
	  } else {
	    $fi_r .= $fi_res;
	  }
	} else {
	  return $fi_res;		# Undefined means abort processing
	}
      } else {
	if (defined $fi_ofh) {
	  print $fi_ofh $fi_res;
	} else {
	  $fi_r .= $fi_res;
	}
      }
    } else {
      die "Can't happen error #2";
    }
  }

  warn "LOOP ERROR: $loop_depth unmatched curlies!" if $loop_depth;

  _scrubpkg($fi_eval_package) if $fi_scrub_package;
  defined $fi_ofh ? 1 : $fi_r;
}

#-----------------------------------------------------------------#

package Text::Template::Simple; # home, sweet home :)
use strict;
use vars qw[$VERSION];

$VERSION = '0.2';

sub new {
   my $class  = shift;
   my %option = scalar @_ % 2 ? () : (@_);
   foreach my $k (keys %option) { # delimiters; global; dummy; reset_dummy; extend
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

   $Text::Template::Simple::Sub::EXTEND = $self->{extend} ? 1 : 0;
   $Text::Template::Simple::Sub::DEBUG  = $self->{debug}  ? 1 : 0;

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
   if ($params && (!ref($params) || ref $params ne 'HASH')) {
      die("Unvalid parameter value! It must be a HASHREF! $params");
   }
   my $template = Text::Template::Simple::Sub->new(
      TYPE       => 'STRING', 
      SOURCE     => $source,
      DELIMITERS => $self->{delimiters},
   ) or die("Couldn't construct the page template: $Text::Template::ERROR");
   my $prepend = $params ? sprintf($self->{define_type}, join($self->{symbol_delim}, $self->prepare_symbols($params))) : '';
   my $text = $template->fill_in(PACKAGE => $self->{dummy},
                                 HASH    => $params ? $params : {},
                    ($prepend ? (PREPEND => $prepend) : ()),
              ) or die("Couldn't fill in template: $Text::Template::ERROR");
   if ($self->{reset_dummy}) {
      # Reset dummy class' symbol table explicitly. 
      # This may be deleted in future releases. 
      # Seems to be unnecessary and buggy...
      eval 'undef %'.$self->{dummy}.'::;';
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
      globals => {
         foo  => 'bar'  , # define $foo
         bar  => ['baz'], # define @bar
         blah => {        # define %blah
            key => 'value',
         },
      },
   );

   my $result = $template->compile(
                  'Hello <%$foo%>. Key is: <%$blah{key}%> and Your name is <%$name%>.',
                  {
                     name => 'Burak',
                  });
   print $result;

=head1 DESCRIPTION

This module provides a simple and high level access to C<Text::Template>
interface. It also adds a C<PREPEND> parameter to enable C<strict>
mode and define the variables before using them. If your perl version is 
smaller than C<5.6>; the C<vars> pragma, and if it is greater; C<our> 
function will be used to define variables in the template. Main purpose 
of this module is to setup that variable definiton code and initialize all
variables if any of them has the value C<undef>.

=head1 METHODS

=head2 new

The object constructor. Takes several parameters:

=head3 delimiters

The default delimiter set is: C<E<lt>% %E<gt>>. You can pass your own
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

=head3 extend

If this has a true value, you can use loop constructs in templates,
instead of modifying the C<$OUT> variable directly. However, there 
are some caveats. Here is a sample template:

   <% foreach (qw[Perl SomeOtherLang]) { %>
      <% if ($_ =~ /perl/i) {%>
         $_ rules!\n
      <% } else { %>
         $_ sux!\n
      <% } %>
   <%}%>

Which is nearly (because the whitespaces around the 
string is also included in the result of above template) 
equal to this regular template code:

   <%
   foreach (qw[Perl SomeOtherLang]) {
      if ($_ =~ /perl/i) {
         $OUT .= qq~$_ rules!\n~;
      } else {
         $OUT .= qq~$_ sux!\n~;
      }
   }
   %>

When you use the extended interface, be aware that you B<can not>
use templates B<inside> the constructs. They are basically 
perl strings (i.e. they are not static template texts). So, 
you can use symbols like C<\n> or C<\r> or any variable 
directly, also any whitespace you put before or after the 
string will be printed too:

      <% if ($_ =~ /perl/i) {%>
         $_ rules!\n
      <% } %>

If there are some curlies that aren't balanced while parsing 
the template, you'll get this warning:

   LOOP ERROR: %d unmatched curlies!

%d can be positive or negative. Negative value indicates that
the parser closed an un-opened loop (i.e. you have an extra 
right curly or your loop start misses a left curly).

C<extend> is disabled by default and behaviour is considered 
experimental. 

=head4 Why extend?

Because I'm tired of writing this all the time:

   $OUT .= qq~blah blah blah~;

this one seems more simple:

   blah blah blah

=head3 debug

If set to a true value, interface will C<warn> you about the 
template compiling process. Currently, it'll not give you any
useful information unless you want to patch C<Text::Template::Simple>.

Debugging is disabled by default.

=head2 compile TEMPLATE, PARAMS

Compiles the template into its final form. Takes two parameters. First 
parameter is the raw template code as a string and second is the 
parameters you can set. C<PARAMS> must be a C<HASHREF>.

   my $result = $template->compile('Your name is {$name}.',
                  {
                     name => 'Burak', # set $name
                  });

=head1 BUGS

=over 4

=item *

B<Complete interface of C<Text::Template> is B<not> supported>

=item *

B<Parameter names can not start with minus>

Example: C<-dummy> or C<-Dummy> is unvalid. Use C<dummy> or C<Dummy>
or C<DUMMY> etc...

=item *

B<Only single string data is accepted as a template text>

Filehandles and any other things are not supported. You must supply a 
single text parameter as the template code.

=item *

B<C<SAFE>, C<BROKEN_ARG> and friends are not supported>

Many parameters of C<Text::Template> are not supported.

=item *

B<Extended interface has some issues>

When using C<extend>ed interface, you have to use this style:

   <% if (condition) { %>
   foo
   <% } elsif (condition) { %>
   bar
   <% } else { %>
   baz
   <% } %>

If you use curlies separately, you'll probably broke the code
and get errors:

   <% if (condition) { %>
   foo
   <% } %>
   <% elsif (condition) { %>
   bar
   <% } %>
   <% else { %>
   baz
   <% } %>

This is not a good style anyway (at least in my opinion). The other
thing you must not do is putting comments or other things above loops:

   <% 
   # blah blah blah
   if (1) {
   %>
      blah
   <% } %>

or

   <% 
   my $blah = 1;
   if ($blah) {
   %>
      blah
   <% } %>

They'll break the current implementation. You can replace the 
C<if>s above with C<while>, C<for> and C<foreach>. The same 
rules apply to all of them.

=item

=back

There may be many more... Please report if you find any bugs.

=head1 SEE ALSO

L<Text::Template>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2005 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.6 or, 
at your option, any later version of Perl 5 you may have available.

=cut
