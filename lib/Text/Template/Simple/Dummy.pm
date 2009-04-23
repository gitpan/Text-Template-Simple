package Text::Template::Simple::Dummy;
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Caller;
use Text::Template::Simple::Util qw();

$VERSION = '0.62_16';

sub stack { # just a wrapper
   my $opt = shift || {};
   Text::Template::Simple::Util::fatal('tts.caller.stack.hash')
      if ! Text::Template::Simple::Util::ishref($opt);
   $opt->{frame} = 1;
   Text::Template::Simple::Caller->stack( $opt );
}

1;

__END__

=head1 NAME

Text::Template::Simple::Dummy - Container class

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This document describes version C<0.62_16> of C<Text::Template::Simple::Dummy>
released on C<23 April 2009>.

B<WARNING>: This version of the module is part of a
developer (beta) release of the distribution and it is
not suitable for production use.

All templates are compiled into this class.

=head1 FUNCTIONS

C<Text::Template::Simple::Dummy> contains some utility functions
that are accessible by all templates.

=head2 stack

Issues a full stack trace and returns the output as string dump. Accepts
options as a hashref:

   stack({ opt => $option, frame => $backtrace_level });

Can be used inside templates like this:

   <%= stack() %>

See L<Text::Template::Simple::Caller> for more information.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
