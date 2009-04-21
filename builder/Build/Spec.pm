package Build::Spec;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
use Exporter ();
use Carp qw( croak );

$VERSION   = '0.50';
@ISA       = qw( Exporter );
@EXPORT    = qw( spec );
@EXPORT_OK = qw( mm_spec );

sub spec () {
    my $file = 'SPEC';
    my $spec = do $file;
      $@                     ? croak "Couldn't parse $file: $@"
    : ! defined $spec && $!  ? croak "Couldn't do $file: $!"
    : ! $spec                ? croak "$file did not return a true value"
    : ref($spec) ne 'HASH'   ? croak "Return type of $file is not HASH"
    : ! $spec->{module_name} ? croak "The specification returned from $file does"
                                    ." not have the mandatory 'module_name' key"
    : return %{ $spec };
    ;
}

sub trim {
    my $s = shift;
    return $s if ! $s;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}

# Makefile.PL related things

sub mm_spec () {
    my %spec = spec();
    (my $file = $spec{module_name}) =~ s{::}{/}g;
    $spec{VERSION_FROM} = "lib/$file.pm";
    $spec{PREREQ_PM}    = { %{ $spec{requires} }, %{ $spec{build_requires} } };
    _mm_recommend( %spec );
    $spec{ABSTRACT} = _mm_abstract( $spec{VERSION_FROM} );
    return %spec;
}

sub _mm_recommend {
    my %spec = @_;
    return if ! $spec{recommends};
    my %rec  = %{ $spec{recommends} } or return;
    my $info = "\nRecommended Modules:\n\n";
    foreach my $m ( sort keys %rec ) {
        $info .= sprintf "\t%s\tv%s\n", $m, $rec{$m};
    }
    print "$info\n";
}

sub _mm_abstract {
    my $file = shift;
    require IO::File;
    my $fh = IO::File->new;
    $fh->open( $file, 'r' ) || croak "Can not read $file: $!";
    binmode $fh;
    while ( my $line = readline $fh ) {
        chomp $line;
        last if $line eq '=head1 NAME';
    }
    my $buf;
    while ( my $line = readline $fh ) {
        chomp $line;
        last if $line =~ m{ \A =head }xms;
        $buf .= $line;
    }
    $fh->close || croak "Can not close $file: $!";
    croak "Unable to get ABSTRACT" if ! $buf;
    $buf = trim( $buf );
    my($mod, $desc) = split m{\-}xms, $buf, 2;
    $desc = trim( $desc ) || croak "Unable to get ABSTRACT";
    return $desc;
}

1;

__END__
