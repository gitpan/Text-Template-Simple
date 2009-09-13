package Text::Template::Simple::Compiler;
# the "normal" compiler
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Dummy;

$VERSION = '0.81';

sub _compile { shift; return eval shift }

1;

__END__

=head1 NAME

Text::Template::Simple::Compiler - Compiler

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.81> of C<Text::Template::Simple::Compiler>
released on C<13 September 2009>.

Template compiler.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2009 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
