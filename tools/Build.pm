use strict;
use vars qw( $VERSION );
use warnings;
use File::Find;
use File::Spec;
use File::Path;
use constant RE_VERSION_LINE => qr{
   \A \$VERSION \s+ = \s+ ["'] (.+?) ['"] ; (.+?) \z
}xms;
use constant RE_POD_LINE => qr{
\A =head1 \s+ DESCRIPTION \s+ \z
}xms;
use constant VTEMP  => q{$VERSION = '%s';};
use constant MONTHS => qw(
   January February March     April   May      June
   July    August   September October November December
);
use constant EXPORTER => 'BEGIN { require Exporter; }';

$VERSION = '0.30';

sub ACTION_dist {
   my $self = shift;
   warn  sprintf(
            "RUNNING 'dist' Action from subclass %s v%s\n",
            ref($self),
            $VERSION
         );
   my @modules;
   find {
      wanted => sub {
         my $file = $_;
         return if $file !~ m{ \. pm \z }xms;
         $file = File::Spec->catfile( $file );
         push @modules, $file;
         warn "FOUND Module: $file\n";
      },
      no_chdir => 1,
   }, "lib";
   $self->_change_versions( \@modules );
   $self->_build_monolith(  \@modules );
   $self->SUPER::ACTION_dist( @_ );
}

sub _change_versions {
   my $self  = shift;
   my $files = shift;
   my $dver  = $self->dist_version;

   my($mday, $mon, $year) = (localtime time)[3, 4, 5];
   my $date = join ' ', $mday, [MONTHS]->[$mon], $year + 1900;

   warn "CHANGING VERSIONS\n";
   warn "\tDISTRO Version: $dver\n";

   foreach my $mod ( @{ $files } ) {
      warn "\tPROCESSING $mod\n";
      my $new = $mod . '.new';
      open my $RO_FH, '<:raw', $mod or die "Can not open file($mod): $!";
      open my $W_FH , '>:raw', $new or die "Can not open file($new): $!";

      CHANGE_VERSION: while ( my $line = readline $RO_FH ) {
         if ( $line =~ RE_VERSION_LINE ) {
            my $oldv      = $1;
            my $remainder = $2;
            warn "\tCHANGED Version from $oldv to $dver\n";
            printf $W_FH VTEMP . $remainder, $dver;
            last CHANGE_VERSION;
         }
         print $W_FH $line;
      }

      my $ns  = $mod;
         $ns  =~ s{ [\\/]     }{::}xmsg;
         $ns  =~ s{ \A lib :: }{}xms;
         $ns  =~ s{ \. pm \z  }{}xms;
      my $pod = "\nThis document describes version C<$dver> of C<$ns>\n"
              . "released on C<$date>.\n"
              ;

      if ( $dver =~ m{[_]}xms ) {
         $pod .= "\nB<WARNING>: This version of the module is part of a\n"
              .  "developer (beta) release of the distribution and it is\n"
              .  "not suitable for production use.\n";
      }

      CHANGE_POD: while ( my $line = readline $RO_FH ) {
         print $W_FH $line;
         print $W_FH $pod if $line =~ RE_POD_LINE;
      }

      close $RO_FH or die "Can not close file($mod): $!";
      close $W_FH  or die "Can not close file($new): $!";

      unlink($mod) || die "Can not remove original module($mod): $!";
      rename( $new, $mod ) || die "Can not rename( $new, $mod ): $!";
      warn "\tRENAME Successful!\n";
   }

   return;
}

sub _build_monolith {
   my $self   = shift;
   my $files  = shift;
   my $dir    = File::Spec->catdir( qw( monolithic_version Text Template ) );
   my $mono   = File::Spec->catfile( $dir, 'Simple.pm' );
   my $buffer = File::Spec->catfile( $dir, 'buffer.txt' );
   my $readme = File::Spec->catfile( qw( monolithic_version README ) );
   my $copy   = $mono . '.tmp';

   mkpath $dir;

   warn "STARTING TO BUILD MONOLITH\n";
   open my $MONO  , '>:raw', $mono   or die "Can not open file($mono): $!";
   open my $BUFFER, '>:raw', $buffer or die "Can not open file($buffer): $!";

   my %add_pod;
   my $POD = '';

   my @files;
   my $c;
   foreach my $f ( @{ $files }) {
      my(undef, undef, $base) = File::Spec->splitpath($f);
      if ( $base eq 'Constants.pm' ) {
         $c = $f;
         next;
      }
      push @files, $f;
   }
   push @files, $c;

   MONO_FILES: foreach my $mod ( reverse @files ) {
      my(undef, undef, $base) = File::Spec->splitpath($mod);
      warn "\tMERGE $mod\n";
      my $is_eof = 0;
      my $is_pre = $base eq 'Constants.pm' || $base eq 'Util.pm';
      open my $RO_FH, '<:raw', $mod or die "Can not open file($mod): $!";
      MONO_MERGE: while ( my $line = readline $RO_FH ) {
         #print $MONO "{\n" if ! $curly_top{ $mod }++;
         my $chomped  = $line;
         chomp $chomped;
         $is_eof++ if $chomped eq '1;';
         my $no_pod   = $is_eof && $base ne 'Simple.pm';
         $no_pod ? last MONO_MERGE
                 : do {
                     warn "\tADD POD FROM $mod\n"
                        if $is_eof && ! $add_pod{ $mod }++;
                  };
         $is_eof ? do { $POD .= $line; }
                : do {
                     print { $is_pre ? $BUFFER : $MONO } $line;
                  };
      }
      close $RO_FH;
      #print $MONO "}\n";
   }
   close $MONO;
   close $BUFFER;

   ADD_PRE: {
      require File::Copy;
      File::Copy::copy( $mono, $copy ) or die "Copy failed: $!";
      my @inc_files = map {
                        my $f = $_;
                        $f =~ s{    \\   }{/}xmsg;
                        $f =~ s{ \A lib/ }{}xms;
                        $f;
                     } @{ $files };

      my @packages = map {
                  my $m = $_;
                  $m =~ s{ [.]pm \z }{}xms;
                  $m =~ s{  /       }{::}xmsg;
                  $m;
               } @inc_files;

      open my $W,    '>:raw', $mono   or die "Can not open file($mono): $!";
      open my $TOP,  '<:raw', $buffer or die "Can not open file($buffer): $!";
      open my $COPY, '<:raw', $copy   or die "Can not open file($copy): $!";

      printf $W q/BEGIN { $INC{$_} = 1 for qw(%s); }/, join(' ', @inc_files);
      print  $W "\n";

      foreach my $name ( @packages ) {
         print $W qq/package $name;\nsub ________monolith {}\n/;
      }

      while ( my $line = readline $TOP ) {
         print $W $line;
      }

      while ( my $line = readline $COPY ) {
         print $W $line;
      }

      close  $W;
      close  $COPY;
      close  $TOP;
   }

   if ( $POD ) {
      open my $MONOX, '>>:raw', $mono or die "Can not open file($mono): $!";
      my $pod = "\nB<WARNING>! This is the monolithic version of Text::Template::Simple\n"
               ."generated with an automatic build tool. If you experience problems\n"
               ."with this version, please install and use the supported standard\n"
               ."version. This version is B<NOT SUPPORTED>.\n"
              ;
      foreach my $line ( split /\n/, $POD ) {
         print $MONOX $line, "\n";
         print $MONOX $pod if "$line\n" =~ RE_POD_LINE;
      }
      close $MONOX;
   }

   unlink $buffer or die "Can not delete $buffer $!";
   unlink $copy   or die "Can not delete $copy $!";
   print "\t";
   system( perl => '-wc', $mono ) && die "$mono does not compile!\n";

   PROVE: {
      warn "\tTESTING MONOLITH\n";
      local $ENV{TTS_TESTING_MONOLITH_BUILD} = 1;
      my @output = qx(prove -Isingle);
      print "\t$_" for @output;
      chomp(my $result = $output[-1]);
      if ( $result ne 'Result: PASS' ) {
         die "\nFAILED! Building the monolithic version failed during unit testing\n\n";
      }
   }

   warn "\tADD README\n";
   open my $README, '>:raw', $readme or die "Can not open file($readme): $!";
   print $README "This monolithic version is NOT SUPPORTED!\n";
   close $README;

   warn "\tADD TO MANIFEST\n";
   (my $monof   = $mono  ) =~ s{\\}{/}xmsg;
   (my $readmef = $readme) =~ s{\\}{/}xmsg;
   open my $MANIFEST, '>>:raw', 'MANIFEST' or die "Can not open MANIFEST: $!";
   print $MANIFEST "$readmef\n";
   print $MANIFEST "$monof\tThe monolithic version of Text::Template::Simple",
                   " to ease dropping into web servers\n";
   close $MANIFEST;
}

1;
