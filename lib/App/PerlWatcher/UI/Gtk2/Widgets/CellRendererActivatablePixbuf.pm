package App::PerlWatcher::UI::Gtk2::Widgets::CellRendererActivatablePixbuf;
{
  $App::PerlWatcher::UI::Gtk2::Widgets::CellRendererActivatablePixbuf::VERSION = '0.07_2';
}
# ABSTRACT: CellRenderer with triggers some action on clicking on some image in cell

use 5.12.0;
use strict;
use warnings;

use Gtk2;

use Glib::Object::Subclass
    Gtk2::CellRendererPixbuf::,
    signals => {
        activated => {
            param_types => ['Glib::String'],
        },
    },
    properties => [];

sub INIT_INSTANCE {
    my $self = shift;
    $self->set(mode => 'activatable');
}

sub ACTIVATE {
    my ($cell, $event, $widget, $path, $background_area, $cell_area, $flags) = @_;
    if($cell->get('pixbuf')){
        $cell->signal_emit("activated", $path);
        return 1;
    }
    return 0;
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::Gtk2::Widgets::CellRendererActivatablePixbuf - CellRenderer with triggers some action on clicking on some image in cell

=head1 VERSION

version 0.07_2

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
