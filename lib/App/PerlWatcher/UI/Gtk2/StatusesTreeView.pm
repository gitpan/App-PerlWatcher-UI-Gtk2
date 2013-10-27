package App::PerlWatcher::UI::Gtk2::StatusesTreeView;
{
  $App::PerlWatcher::UI::Gtk2::StatusesTreeView::VERSION = '0.07_1';
}

use 5.12.0;
use strict;
use warnings;

use aliased 'App::PerlWatcher::UI::Gtk2::Widgets::CellRendererActivatablePixbuf' => 'CRAP';
use aliased 'App::PerlWatcher::Level' => 'Level', qw/:levels/;
use App::PerlWatcher::Openable;
use App::PerlWatcher::UI::Gtk2::Utils qw/get_level_icon get_icon/;
use App::PerlWatcher::UI::Gtk2::URLOpener;
use Devel::Comments;
use Gtk2;
use List::Util qw/first/;
use POSIX qw(strftime);

use base 'Gtk2::TreeView';

sub new {
    my $class = shift;
    my ($tree_store, $app) = @_;
    # create an entry
    my $self = Gtk2::TreeView->new($tree_store);
    my $open_delay = $app->config->{open_url_delay} // 1;
    my $url_opener = App::PerlWatcher::UI::Gtk2::URLOpener->new(
        delay    => $open_delay,
        callback => sub { $self->_unmark_opening(shift); },
    );
    $self->{_tree_store   } = $tree_store;
    $self->{_app          } = $app;
    $self->{_url_opener   } = $url_opener;

    bless $self, $class;
    $self->_construct;
    return $self;
}

sub _is_unseen {
    my ($self, $status) = @_;
    my $last_seen = $self -> {_app} -> last_seen;
    # check if status has been updated
    #my $r = $status->timestamp > $last_seen;
    my $r = $self->{_tree_store}->shelf->status_changed($status);
    return $r;
}


sub _unmark_opening {
    my ($self, $openables) = @_;

};

sub _open_url {
    my ($self, $openable) = @_;
    $self->{_url_opener}->delayed_open($openable);
}

sub _get_status_icon {
    my ($self, $status) = @_;
    return get_level_icon($status->level, $self->_is_unseen($status));
}

sub _get_openable_icon {
    my ($self, $openable) = @_;
    my $is_opening = first { $_ == $openable }
        @{ $self->{_url_opener}->openables };
    my $icon_name = $is_opening ? 'opening-link' : 'open-link';
    return get_icon($icon_name);
}

sub _construct {
    my $self = shift;
    $self -> _constuct_icon_column;
    $self -> _constuct_description_column;
    $self -> _constuct_activation_column;
    $self -> _constuct_actions_column;
    $self -> _constuct_timestamp_column;
}

sub _constuct_actions_column {
    my $self = shift;
    my $renderer = CRAP->new;
    my $column = Gtk2::TreeViewColumn->new;
    $column->pack_start( $renderer, 0 );
    $self->append_column($column);
    $column->set_cell_data_func(
        $renderer,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            my $pixbuff =
                $value->does('App::PerlWatcher::Openable')
                ? $self->_get_openable_icon($value)
                :  undef;
            $cell->set(pixbuf => $pixbuff)
        }
    );
    my $model = $self->{_tree_store};
    $renderer->signal_connect("activated" => sub {
            ### got activation signal
            my ( $cell, $path ) = @_;
            my $iter = $model->get_iter_from_string($path);
            my $openable = $model->get_value( $iter, 0 );
            $self->_open_url($openable);
    });
}

sub _constuct_icon_column {
    my $self = shift;
    my $renderer_icon = Gtk2::CellRendererPixbuf->new;
    $renderer_icon->set('stock-id' => 1);

    my $column_icon = Gtk2::TreeViewColumn->new;
    $column_icon->pack_start( $renderer_icon, 0 );
    $self->append_column($column_icon);
    $column_icon->set_cell_data_func(
        $renderer_icon,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            if ( $value->isa('App::PerlWatcher::Status') ) {
                my $pixbuff = $self->_get_status_icon($value);
                $cell->set( pixbuf => $pixbuff)
                    if $pixbuff;
            } else {
                $cell->set( pixbuf => undef);
            }
        }
    );
}

sub _constuct_description_column {
    my $self = shift;
    my $renderer_desc = Gtk2::CellRendererText->new;
    $renderer_desc->set( ellipsize => 'end', 'width-chars' => 100 );

    my $column_desc = Gtk2::TreeViewColumn->new;
    $column_desc->pack_start( $renderer_desc, 0 );
    $column_desc->set_title('_description');
    $self->append_column($column_desc);
    $column_desc->set_cell_data_func(
        $renderer_desc,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            my $text;
            if ( $value->isa('App::PerlWatcher::Status') ) {
                my $status = $value;
                $text = $status->description->();
                $text = "<b>$text</b>" if ($self->_is_unseen($status));
                $cell->set( markup => "$text" );
            }
            else {
                $cell->set( text => $value -> content );
            }

        }
    );
}

sub _constuct_activation_column {
    my $self = shift;
    my $tree_store = $self -> {_tree_store};
    my $renderer_toggle = Gtk2::CellRendererToggle->new;
    $renderer_toggle->set( activatable => 1 );
    $renderer_toggle->signal_connect(
        "toggled" => sub {
            my ( $renderer, $path ) = @_;
            ## $path
            my $iter           = $tree_store->get_iter_from_string($path);
            my $status         = $tree_store->get_value( $iter, 0 );
            my $w              = $status->watcher;
            my $current_active = $w->active;
            $w->active( !$current_active );
        },
        $tree_store
    );

    my $column_toggle = Gtk2::TreeViewColumn->new;
    $column_toggle->pack_start( $renderer_toggle, 1 );
    $column_toggle->set_title('_active');
    $self->append_column($column_toggle);
    $column_toggle->set_cell_data_func(
        $renderer_toggle,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            if ( $value->isa('App::PerlWatcher::Status') ) {
                my $status = $value;
                $cell->set( active  => $status->watcher->active );
                $cell->set( visible => 1 );
            }
            else {
                $cell->set( visible => 0 );
            }

        }
    );
}

sub _constuct_timestamp_column {
    my $self = shift;
    my $renderer_timestamp = Gtk2::CellRendererText->new;
    my $column_timestamp = Gtk2::TreeViewColumn->new;
    $column_timestamp->pack_start( $renderer_timestamp, 2 );
    $column_timestamp->set_title('_timestamp');
    $self->append_column($column_timestamp);
    $column_timestamp->set_cell_data_func(
        $renderer_timestamp,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            my $timestamp = $value->timestamp;
            my $text = $timestamp ? strftime('%H:%M:%S',localtime $timestamp)
                                  : q{}
                                  ;
            ## $text
            $cell->set( text => $text );
        }
    );
}

1;
