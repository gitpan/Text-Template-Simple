package Text::Template::Simple::Compiler;
# the "normal" compiler
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Dummy;

$VERSION = '0.54_02';

sub _compile { shift; return eval shift }

1;

__END__

=head1 NAME

Text::Template::Simple::Compiler - Compiler

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Template compiler.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
