use strict;
use vars qw( %PREREQ %RECOMMEND $AUTHOR $MODULE );
use Module::Build;

do 'PREREQ' or die "Can not include PREREQ: $@";

# getting dumb error messages. maybe related to an old version?
$PREREQ{'Module::Build'} = '0.2808';

my $mb = Module::Build->new(
    module_name => $MODULE,
    license     => 'perl',
    requires    => \%PREREQ,
    recommends  => \%RECOMMEND,
    sign        => 0,
    dist_author => $AUTHOR,
);

$mb->create_build_script;
