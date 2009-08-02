use strict;
use lib qw( builder );
use Build;

my $mb = Build->new;
$mb->change_versions(1);
$mb->build_monolith(1);
$mb->monolith_add_to_top( [ qw( Constants.pm Util.pm ) ] );
$mb->taint_mode_tests(1);
$mb->copyright_first_year( 2004 );
$mb->add_pod_author_copyright_license(1);
$mb->create_build_script;
