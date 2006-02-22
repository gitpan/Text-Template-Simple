use strict;
use Module::Build;

Module::Build->new(
   module_name => 'Text::Template::Simple',
   license     => 'perl',
   requires    => {
      'Data::Dumper' => '2.101',
      'File::Spec'   => '0.6',
      'File::Find'   => 0,
      'IO::Handle'   => '1.1505',
      'IO::File'     => '1.06021',
      'Fcntl'        => '1.03',
      'Safe'         => '2.06',
   },
   recommends  => {
      'Devel::Size'  => '0.64',
   },
   sign        => 0,
   dist_author => 'Burak Gursoy <burak@cpan.org>',
)->create_build_script;
