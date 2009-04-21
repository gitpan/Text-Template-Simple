#!/usr/bin/env perl
use strict;
use ExtUtils::MakeMaker;

my %opt  = do 'SPEC' or die "Can not include PREREQ: $@";
my $info = "\nRecommended Modules:\n\n";

foreach my $m ( sort keys %{ $opt{recommends} } ) {
    $info .= sprintf "    %s\tv%s\n", $m, $opt{recommends}->{$m};
}

print "$info\n";

(my $FILE = $opt{module_name}) =~ s{::}{/}g;

WriteMakefile(
    NAME         => $opt{module_name},
    VERSION_FROM => "lib/$FILE.pm",
    PREREQ_PM    => { %{ $opt{requires} }, %{ $opt{build_requires} } },
    PL_FILES     => {},
    ($] >= 5.005 ? (
    AUTHOR       => $opt{dist_author},
    ABSTRACT     => 'Simple text template engine',
    ) : ()),
);
