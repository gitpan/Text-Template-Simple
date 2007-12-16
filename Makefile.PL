use ExtUtils::MakeMaker;

print <<'RECOMMEND';

Recommended Modules:

   Devel::Size v0.64
   Text::Table v1.107
   Perl::Tidy

RECOMMEND

WriteMakefile(
   'NAME'         => 'Text::Template::Simple',
   'VERSION_FROM' => 'lib/Text/Template/Simple.pm',
   'PREREQ_PM'    => {
      'Data::Dumper' => '2.101',
      'File::Spec'   => '0.6',
      'File::Find'   => 0,
      'IO::Handle'   => '1.1505',
      'IO::File'     => '1.06021',
      'Fcntl'        => '1.03',
      'Safe'         => '2.06',
      'Test::More'   => '0.40',
      #'Devel::Size'  => 0,
   },
   ($] >= 5.005 ? (
   AUTHOR   => 'Burak Gursoy <burak@cpan.org>',
   ABSTRACT => 'Simple text template engine',
   ) : ()),
   PL_FILES => {},
);
