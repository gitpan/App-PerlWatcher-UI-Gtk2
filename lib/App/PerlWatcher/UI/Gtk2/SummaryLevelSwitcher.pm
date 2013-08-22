package App::PerlWatcher::UI::Gtk2::SummaryLevelSwitcher;
{
  $App::PerlWatcher::UI::Gtk2::SummaryLevelSwitcher::VERSION = '0.05';
}

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Gtk2;
use List::MoreUtils qw/first_index/;

use App::PerlWatcher::Levels;
use App::PerlWatcher::UI::Gtk2::Utils qw/get_level_icon/;

use base 'Gtk2::ComboBox';

sub new {
    my ($class, $app, $cb) = @_;
    my $self = Gtk2::ComboBox->new;
    bless $self, $class;

    my $model = $self->_create_levels_model;
    $self->_create_renderers;

    $self->{_app    } = $app;
    $self->set_model($model);

    $self->signal_connect(changed => sub {
            my $active_iter = $self->get_active_iter;
            my $level = $self->get_model->get_value($active_iter, 0 );
            $cb->($level);
    });
    return $self;
}

sub set_active_level {
    my ($self, $level) = @_;
    my $idx = first_index { $_ == $level } @App::PerlWatcher::Levels::ALL_LEVELS;
    $self->set_active($idx);
}

sub _create_levels_model {
    my $self = shift;
    my $model = Gtk2::ListStore->new(qw/Glib::Scalar/);
    $model->set($model->append, 0, $_)
        for(@App::PerlWatcher::Levels::ALL_LEVELS);
    return $model;
}

sub _create_renderers {
    my $self = shift;
    $self->_create_icon_renderer;
    $self->_create_label_renderer;
}

sub _create_icon_renderer {
    my $self = shift;
    my $renderer_icon = Gtk2::CellRendererPixbuf->new;
    $self->pack_start($renderer_icon, 0);
    $self->set_cell_data_func(
        $renderer_icon, sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $level = $model->get_value( $iter, 0 );
            my $pixbuff = get_level_icon($level, 0);
            $cell->set( pixbuf => $pixbuff)
        }
    );
}

sub _create_label_renderer {
    my $self = shift;
    my $renderer_label = Gtk2::CellRendererText->new;
    $self->pack_start($renderer_label, 0);
    $self->set_cell_data_func(
        $renderer_label, sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $level = $model->get_value( $iter, 0 );
            $cell->set(text => "$level" );
        }
    );
}

sub considered_active {
    return shift->get('popup-shown');
}

1;
