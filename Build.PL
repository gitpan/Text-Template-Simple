use strict;
use vars qw( %PREREQ %RECOMMEND $AUTHOR $MODULE );
use Module::Build;
use File::Spec;
use IO::File;

do 'PREREQ' or die "Can not include PREREQ: $@";

# getting dumb error messages. maybe related to an old version?
$PREREQ{'Module::Build'} = '0.2808';

my $class = Module::Build->subclass(
                class => 'MBSubclass',
                code  => raw_subclass(),
            );

my $mb = $class->new(
    module_name    => $MODULE,
    license        => 'perl',
    requires       => \%PREREQ,
    recommends     => \%RECOMMEND,
    sign           => 0,
    dist_author    => $AUTHOR,
    create_license => 1,
    no_index       => {
        directory => [
            'monolithic_version',
            'tools',
        ]
    },
    meta_merge => {
        resources => {
            repository => 'http://bitbucket.org/burak/cpan-text-template-simple/',
        },
    },
);

$mb->create_build_script;

sub raw_subclass {
    my $file = File::Spec->catfile( 'tools', 'Build.pm' );
    my $FH   = IO::File->new;
    $FH->open( $file, 'r' ) or die "Can not open($file): $!";
    my $rv = do { local $/; <$FH> };
    close $FH;
    return $rv;
}
