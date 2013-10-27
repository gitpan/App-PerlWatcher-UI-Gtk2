package App::PerlWatcher::UI::Gtk2::Utils;
{
  $App::PerlWatcher::UI::Gtk2::Utils::VERSION = '0.07_2';
}
# ABSTRACT: Helping functions for Gtk2 app

use 5.12.0;
use strict;
use warnings;

use Carp;
use Devel::Comments;
use File::ShareDir::ProjectDistDir ':all';
use Gtk2;
use Memoize;

use App::PerlWatcher::Level qw/:levels/;

use parent qw/Exporter/;

our @EXPORT_OK = qw/get_level_icon get_icon get_icon_file/;

sub get_icon_file {
    my $relative_path = shift;
    return dist_file('App-PerlWatcher-UI-Gtk2', $relative_path);
}

memoize('get_level_icon');
sub get_level_icon {
    my ($level, $unseen) = @_;
    my $postfix = $unseen ? "_new" : "";
    my $filename = get_icon_file("assets/icons/${level}${postfix}.png");
    return unless -r $filename;
    my @icon_size = Gtk2::IconSize->lookup('menu');
    my $pixbuff = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($filename, @icon_size, 1);
    return $pixbuff;
}

sub get_icon {
    my $icon = shift;
    my $filename = get_icon_file("assets/icons/${icon}.png");
    return unless -r $filename;
    my @icon_size = Gtk2::IconSize->lookup('menu');
    my $pixbuff = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($filename, @icon_size, 1);
    return $pixbuff;
}

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::Gtk2::Utils - Helping functions for Gtk2 app

=head1 VERSION

version 0.07_2

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
