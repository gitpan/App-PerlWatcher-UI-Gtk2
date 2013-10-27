package App::PerlWatcher::UI::Gtk2::Application;
{
  $App::PerlWatcher::UI::Gtk2::Application::VERSION = '0.07_2';
}
# ABSTRACT: Main application class for Gtk2 frontend for PerlWatcher

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use App::PerlWatcher::Engine;
use App::PerlWatcher::Levels;
use aliased qw/App::PerlWatcher::UI::Gtk2::StatusesModel/;
use aliased qw/App::PerlWatcher::UI::Gtk2::StatusesTreeView/;
use App::PerlWatcher::UI::Gtk2::SummaryLevelSwitcher;
use App::PerlWatcher::UI::Gtk2::Utils qw/get_level_icon get_icon_file/;
use Devel::Comments;
use Gtk2;
use Gtk2::TrayIcon;
use Moo;
use POSIX qw(strftime);
use Scalar::Util qw/weaken/;

with qw/App::PerlWatcher::Frontend/;

has 'config'                => ( is => 'ro', required => 1);
has 'icon'                  => ( is => 'lazy');
has 'icon_widget'           => ( is => 'lazy');
has 'tray_menu'             => ( is => 'lazy');
has 'window'                => ( is => 'lazy');
has 'title'                 => ( is => 'lazy');
has 'statuses_tree'         => ( is => 'lazy');
has 'timers'                => ( is => 'rw', default => sub{ []; } );
has 'summary_level'         => ( is => 'rw', default => sub{ LEVEL_NOTICE; } );
has 'focus_tracked_widgets' => ( is => 'rw', default => sub{ []; } );
has 'statuses_model'        => ( is => 'rw', default => sub{ StatusesModel->new(shift); } );


has 'last_seen'    => ( is => 'rw', default => sub{ time; } );



sub _build_statuses_tree {
    my $self = shift;
    return StatusesTreeView->new($self->statuses_model, $self);
}

sub _build_icon {
    my $self = shift;
    my $icon = Gtk2::TrayIcon->new("test");
    $icon->signal_connect( "button-press-event" => sub {
            # button-press-event
            my ($widget, $event) = @_;
            if ( $event->button == 1 ) { # left
                my ($x, $y) = $event->root_coords;
                $self -> _present($x, $y);
                return 1;
            }
            elsif ( $event->button == 3 ) { # right
                #$self->_mark_as_read;
               $self->tray_menu->popup(undef,undef,undef,undef,0,0);
               $self->tray_menu->show_all;
               return 1;
            }
            return 0;
    });

    my $event_box = Gtk2::EventBox->new;
    $icon->add($event_box);
    $event_box->add($self->icon_widget);
    return $icon;
}

sub _build_icon_widget {
    Gtk2::Image->new;
}

sub _build_title {
    my $self = shift;
    sprintf("%s %s",
        "PerlWatcher",
        $App::PerlWatcher::Engine::VERSION // "dev");
}

sub _build_tray_menu {
    my $self = shift;
    weaken $self;

    my $tray_menu = Gtk2::Menu->new();

    my $menu_read = Gtk2::MenuItem->new('mark all as read');
    $menu_read->signal_connect('activate' => sub {
            $self->_mark_as_read;
    });
    $tray_menu->append($menu_read);

    $tray_menu->append(Gtk2::SeparatorMenuItem->new());

    my $menu_item_quit = Gtk2::MenuItem->new('quit');
    $menu_item_quit->signal_connect('activate' => sub {
            $self->quit;
    });
    $tray_menu->append($menu_item_quit);
    return $tray_menu;
}

sub _build_window {
    my $self = shift;
    my $window = Gtk2::Window->new;

    my $default_size =
      $self->config->{window_size} // [ 500, 300 ];

    #$window->set_default_size(@$default_size);
    $window->set_size_request(@$default_size);
    $window->set_title($self->title);

    #$window -> set_decorated(0);
    #$window -> set_opacity(0); # not works yet
    my $hide_from_taskbar = $self->config->{hide_from_taskbar} // 1;
    $window->set_skip_taskbar_hint($hide_from_taskbar);
    #$window->set_type_hint('tooltip');
    $window->signal_connect( delete_event => \&Gtk2::Widget::hide_on_delete );
    $window->signal_connect('focus-out-event' => sub {
            # focus out
            my $idle_w; $idle_w = AnyEvent->timer(after => 0.5, cb => sub {
                    my $has_tracked_widgets = @{ $self->focus_tracked_widgets };
                    my $child_window_focus = 0;
                    $child_window_focus &&= $_->considered_active
                        for(@{ $self->focus_tracked_widgets });
                    my $do_hide = ($has_tracked_widgets && $child_window_focus);
                    #$do_hide = 0;
                    ### $do_hide
                    if($do_hide) {
                        $window->hide;
                        $self->timers([]); # kill all timers
                        $self->last_seen(time);
                    }
                    undef $idle_w;
             });
            0;
    });
    my $icon_file = get_icon_file("assets/icons/perl_watcher.png");
    $window->set_icon_from_file($icon_file);

    return $window;
}

sub BUILD {
    my $self = shift;
    Gtk2->init;

    $self->_construct_gui;

    $self->_set_label("just started", LEVEL_ANY, 0);
    $self->window->show_all
        unless($self->config->{hide_on_startup});
    return $self;
}

sub update {
    my ( $self, $status ) = @_;
    my $visible = $self->window->get('visible');
    $self->statuses_model->update($status, $visible, sub {
            my $path = shift;
            $self->statuses_tree->expand_row($path, 1);
    });
    #$self->statuses_tree->expand_all;
    $self->_trigger_undertaker if ( $visible );
    $self->_update_summary;
}

sub show {
    my $self = shift;
    $self->icon->show_all();
}

sub quit {
    my $self = shift;
    $self->engine->stop;
}

sub _update_summary {
    my $self = shift;
    my $summary_level = $self->summary_level;
    my $summary = $self->statuses_model->summary($summary_level);
    my $has_updated =  @{ $summary->{updated} };
    my $sorted_statuses = $self->engine->sort_statuses($summary->{updated});
    my $tip = join "\n", map { $_->description->() } @$sorted_statuses;
    $tip = sprintf("%s (notificaiton level: %s)", $self->title,  $summary_level)
        . ($tip ? "\n\n" . $tip : "");
    $self->_set_label($tip, $summary->{max_level}, $has_updated);
}

sub _set_label {
    my ( $self, $tip, $level, $is_new ) = @_;
    my $icon = get_level_icon($level, $is_new);
    $self->icon_widget->set_tooltip_markup($tip);
    $self->icon_widget->set(pixbuf => $icon);
}

sub _construct_gui {
    my $self = shift;

    my $vbox = Gtk2::VBox->new( 0, 3 );
    $self->window->add($vbox);

    my $hbox = Gtk2::HBox->new( 0, 5 );
    $vbox->pack_start( $hbox, 0, 0, 0 );

    my $summary_level_switcher = App::PerlWatcher::UI::Gtk2::SummaryLevelSwitcher
        ->new($self, sub { $self->summary_level(shift) } );
    push @{ $self->focus_tracked_widgets }, $summary_level_switcher;
    $summary_level_switcher->set_active_level($self->summary_level);

    $hbox->pack_start( $summary_level_switcher, 0, 0, 5 );

    my $reset_button = Gtk2::Button->new_with_label('Mark as read');
    $reset_button->signal_connect( 'clicked' => sub {
            $self->_mark_as_read;
    });
    $hbox->pack_end( $reset_button, 1, 1, 0 );

    my $scrolled_window = Gtk2::ScrolledWindow->new;
    $scrolled_window->set_policy("automatic", "automatic");
    $scrolled_window->add($self->statuses_tree);

    $vbox->pack_start($scrolled_window, 1, 1, 0 );
    $vbox->show_all;
}

sub _present {
    my ( $self, $x, $y ) = @_;
    my $window = $self->window;
    #if ( !$window->get('visible') ) {
        $window->hide_all;
        $window->move( $x, $y );
        $window->show_all;
        $window->present;
        $self->_trigger_undertaker;
    #}
}

sub _trigger_undertaker {
    my $self = shift;
    my $idle =
        $self->config->{uninteresting_after} // 5;
    my $timer = AnyEvent->timer (
        after => $idle,
        cb    => sub {
            $self->_mark_as_read;
        },
    );
    push @{ $self->timers }, $timer;
}

sub _mark_as_read {
    my $self = shift;
    $self->timers([]);
    $self->statuses_model->stash_outdated(time);
    $self->_update_summary;
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::Gtk2::Application - Main application class for Gtk2 frontend for PerlWatcher

=head1 VERSION

version 0.07_2

=head1 ATTRIBUTES

=head2 last_seen

The timestamp last seen of user-visible watcher statuses.

=head1 SCREENSHOT

=for HTML <p>
<img src="https://raw.github.com/basiliscos/images/master/PerlWatcher-0.16.png" alt="PerlWatcher GTK2 screenshot" title="PerlWatcher GTK2 screenshot" style="max-width:100%;">
</p>

=head1 CREDITS

Hanna Mineeva

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
