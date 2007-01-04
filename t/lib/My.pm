package My;
use strict;
use vars qw($VERSION);

$VERSION = '0.2';

package Text::Template::Simple::Dummy;
use strict;
# Globals must be defined with vars pragma.
# our() does not work for some reason
use vars qw(%GLOBAL);

%GLOBAL = ( X => "Y" );

sub hello { "Dear $_[0], this is a template function!" }

1;

__END__
