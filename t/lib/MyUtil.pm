package MyUtil;
use strict;
use warnings;
use vars qw( $VERSION @EXPORT );
use base qw( Exporter );
use constant LEGACY_PERL => $] < 5.006;

$VERSION = '0.10';
@EXPORT  = qw( _p LEGACY_PERL );

sub _p { ## no critic (ProhibitUnusedPrivateSubroutines)
    my @args = @_;
    return if print @args;
    warn "@args\n";
    return;
}

1;

__END__
