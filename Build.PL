use strict;
use Module::Build;

Module::Build->new(
   module_name => 'Text::Template::Simple',
   license     => 'perl',
   requires    => { 'Text::Template' => '1.44' },
   recommends  => {},
   sign        => 0,
   dist_author => 'Burak Gursoy <burak@cpan.org>',
)->create_build_script;
