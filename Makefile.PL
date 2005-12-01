use ExtUtils::MakeMaker;

WriteMakefile(
   'NAME'         => 'Text::Template::Simple',
   'VERSION_FROM' => 'lib/Text/Template/Simple.pm',
   'PREREQ_PM'    => {
      'Text::Template' => '1.44',
   },
   ($] >= 5.005 ? (
   AUTHOR   => 'Burak Gursoy <burak@cpan.org>',
   ABSTRACT => 'A simple template class mainly for web applications',
   ) : ()),
   PL_FILES => {},
);
