
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.72;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Gtk2 frontend for perl watcher",
  "AUTHOR" => "Ivan Baidakou <dmol\@gmx.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.72",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "App-PerlWatcher-UI-Gtk2",
  "EXE_FILES" => [
    "bin/perl-watcher-gtk",
    "bin/perl-watcher-gtk"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::PerlWatcher::UI::Gtk2",
  "PREREQ_PM" => {
    "AnyEvent" => "7.04",
    "App::PerlWatcher::Engine" => "0.13",
    "Devel::Comments" => "v1.1.4",
    "File::ShareDir::ProjectDistDir" => "v0.4.4",
    "Gtk2" => "1.247",
    "Gtk2::TrayIcon" => "0.06",
    "List::MoreUtils" => "0.33",
    "Moo" => "1.003000",
    "Scalar::Util" => "1.25",
    "aliased" => "0.31"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


