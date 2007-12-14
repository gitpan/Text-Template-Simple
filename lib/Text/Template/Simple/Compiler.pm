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
