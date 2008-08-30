use strict;
use vars qw( %PREREQ %RECOMMEND $AUTHOR $MODULE );
use Module::Build;

do 'PREREQ' or die "Can not include PREREQ: $@";

Module::Build->new(
    module_name => $MODULE,
    license     => 'perl',
    requires    => \%PREREQ,
    recommends  => \%RECOMMEND,
    sign        => 0,
    dist_author => $AUTHOR,
)->create_build_script;
