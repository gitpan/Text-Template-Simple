package Text::Template::Simple::Compiler;
# Compiling any code inside the template class is 
# like exploding a bomb in a public place.
# Since the compiled code will have access to anything
# inside the compiler method (i.e. cache populator) and 
# to any package globals/lexicals (i.e. $self), they'll 
# all be accessible inside the template code...
#
# So, we explode the bomb in deep space instead ;)
use strict;
use vars qw($VERSION);
use Text::Template::Simple::Dummy;

$VERSION = '0.10';

sub _compile { shift; return eval shift }

1;

__END__

=head1 NAME

Text::Template::Simple::Compiler - Compiler for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Template compiler.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2007 Burak GE<252>rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
