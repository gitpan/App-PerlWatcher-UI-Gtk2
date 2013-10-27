package App::PerlWatcher::UI::Gtk2::Gtk2Backend;
{
  $App::PerlWatcher::UI::Gtk2::Gtk2Backend::VERSION = '0.07_2';
}
# ABSTRACT: Backend class for Gtk2 loop

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

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::Gtk2::Gtk2Backend - Backend class for Gtk2 loop

=head1 VERSION

version 0.07_2

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
