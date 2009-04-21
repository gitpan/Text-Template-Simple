use strict;
use lib qw( builder );
use Build;

my %opt = do 'SPEC' or die "Can not include PREREQ: $@";
my $mb  = Build->new( %opt );
$mb->change_versions(1);
$mb->build_monolith(1);
$mb->monolith_add_to_top( [ qw( Constants.pm Util.pm ) ] );
$mb->create_build_script;
