package App::PerlWatcher::UI::Gtk2::Gtk2Backend;
{
  $App::PerlWatcher::UI::Gtk2::Gtk2Backend::VERSION = '0.06';
}

use 5.12.0;
use strict;
use warnings;

use Moose;
use Gtk2;

with 'App::PerlWatcher::Backend';

sub start_loop {
    Gtk2->main;
}

sub stop_loop {
    Gtk2->main_quit;
}

1;
