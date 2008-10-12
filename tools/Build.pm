use strict;
use vars qw( $VERSION );
use warnings;
use File::Find;
use constant RE_VERSION_LINE => qr{
   \A \$VERSION \s+ = \s+ ["'] (.+?) ['"] ; (.+?) \z
}xms;
use constant VTEMP => q{$VERSION = '%s';};

$VERSION = '0.10';

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
         push @modules, $file;
         warn "FOUND Module: $file\n";
      },
      no_chdir => 1,
   }, "lib";
   $self->_change_versions( \@modules );
   $self->SUPER::ACTION_dist( @_ );
}

sub _change_versions {
   my $self  = shift;
   my $files = shift;
   my $dver  = $self->dist_version;

   warn "DISTRO Version: $dver\n";

   foreach my $mod ( @{ $files } ) {
      warn "PROCESSING $mod\n";
      my $new = $mod . '.new';
      open my $RO_FH, '<:raw', $mod or die "Can not open file($mod): $!";
      open my $W_FH , '>:raw', $new or die "Can not open file($new): $!";
      my $changed;
      while ( my $line = readline $RO_FH ) {
         if ( ! $changed && ( $line =~ RE_VERSION_LINE ) ) {
             my $oldv      = $1;
             my $remainder = $2;
             warn "CHANGED Version from $oldv to $dver\n";
             printf $W_FH VTEMP . $remainder, $dver;
             $changed++;
             next;
         }
         print $W_FH $line;
      }

      close $RO_FH or die "Can not close file($mod): $!";
      close $W_FH  or die "Can not close file($new): $!";

      unlink($mod) || die "Can not remove original module($mod): $!";
      rename( $new, $mod ) || die "Can not rename( $new, $mod ): $!";
      warn "RENAME Successful!\n";
   }

   return;
}
