#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Test::More;

use_ok 'App::PerlWatcher::UI::Gtk2::Application';
use_ok 'App::PerlWatcher::UI::Gtk2::Gtk2Backend';
use_ok 'App::PerlWatcher::UI::Gtk2::StatusesModel';
use_ok 'App::PerlWatcher::UI::Gtk2::StatusesTreeView';
use_ok 'App::PerlWatcher::UI::Gtk2::SummaryLevelSwitcher';
use_ok 'App::PerlWatcher::UI::Gtk2::Utils';
use_ok 'App::PerlWatcher::UI::Gtk2::URLOpener';

done_testing;

