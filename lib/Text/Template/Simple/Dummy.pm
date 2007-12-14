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

$VERSION = '0.10';

sub stack { # just a wrapper
   my $opt = shift || {};
   die "Parameters to stack() must be a HASH" if ref($opt) ne 'HASH';
   $opt->{frame} = 1;
   Text::Template::Simple::Caller->stack( $opt );
}

1;

__END__
