#!/usr/bin/env perl
use strict;
use vars qw( %PREREQ %RECOMMEND $AUTHOR $MODULE );
use ExtUtils::MakeMaker;

do 'PREREQ' or die "Can not include PREREQ: $@";

my $info = "\nRecommended Modules:\n\n";

foreach my $m ( sort keys %RECOMMEND ) {
    $info .= sprintf "    %s\tv%s\n", $m, $RECOMMEND{$m};
}

print "$info\n";

(my $FILE = $MODULE) =~ s{::}{/}g;

WriteMakefile(
    NAME         => $MODULE,
    VERSION_FROM => "lib/$FILE.pm",
    PREREQ_PM    => \%PREREQ,
    PL_FILES     => {},
    ($] >= 5.005 ? (
    AUTHOR       => $AUTHOR,
    ABSTRACT     => 'Simple text template engine',
    ) : ()),
);
