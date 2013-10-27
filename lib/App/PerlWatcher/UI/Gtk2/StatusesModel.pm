package App::PerlWatcher::UI::Gtk2::StatusesModel;
{
  $App::PerlWatcher::UI::Gtk2::StatusesModel::VERSION = '0.07_1';
}

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use App::PerlWatcher::Levels;
use App::PerlWatcher::Shelf;
use aliased 'App::PerlWatcher::Status';
use Carp;
use Devel::Comments;
use List::Util qw/max/;
use Gtk2;
use POSIX qw(strftime);

use base 'Gtk2::TreeStore';

sub new {
    my ($class, $app) = @_;
    my $self = Gtk2::TreeStore->new(qw/Glib::Scalar/);
    $self -> {_watchers} = {};
    $self -> {_engine  } = $app->engine;
    $self -> {_shelf   } = $app->engine->shelf;
    bless $self, $class;
    
    for my $watcher (@{ $app->engine->watchers }) {
        my $iter = $self->append(undef);
        my $status = Status->new(
            watcher     => $watcher,
            level       => LEVEL_ANY,
            description => sub { $watcher->description; },
        );
        $self -> {_watchers}{ $watcher } = {
            status   =>  $status,
            iterator => $iter, 
        };
        $self -> _update_status( $iter, $status); 
    }
          
    return $self;
}

sub update {
    my ( $self, $s, $stash_previous, $new_callback ) = @_;
    my $watcher_info = $self -> {_watchers}{ $s->watcher };
    $self -> {_shelf} -> stash_status($watcher_info->{status})
        if ( $stash_previous );
    my $iter = $watcher_info->{iterator};
    $self -> _update_status( $iter, $s);
    $watcher_info->{status} = $s;
    $new_callback->($self->get_path($iter))
        if $self->{_shelf}->status_changed($s);
}

sub shelf {
    return shift->{_shelf};
}

sub stash_outdated {
    my ($self, $time) = @_;
    my @outdated = 
        grep { $_->timestamp <= $time } 
        map { $_->{status} } 
        values %{ $self -> {_watchers} }; 
    for( @outdated ) {
        if ( $self->{_shelf}->stash_status($_) ) {
            my $iter = $self -> {_watchers}{ $_->watcher }{iterator};
            my $path = $self->get_path($iter);
            # emit event
            $self->row_changed($path, $iter);
        }
    }
}

sub summary {
    my ($self, $minimal_level) = @_;
    my $result = {
        max_level => LEVEL_ANY,
        updated   => [],
    };
    my @statuses =
        map { $_->{status} } 
        values %{ $self -> {_watchers} };
    for ( @statuses ) {
        $result->{max_level} = $_->level
            if ( $result->{max_level} < $_->level );
        push @{ $result->{updated} }, $_  
            if $self->{_shelf}->status_changed($_)
                && $_->level >= $minimal_level;
    }
    return $result;
}

sub _update_status {
    my ($self, $iterator, $status ) = @_;
    $self->set( $iterator, 0 => $status );
    $self->_update_event_items($iterator, $status);
}

sub _update_event_items {
    my ($self, $iter_parent, $status ) = @_;
    # remove all (old) children
    {
        my $child = $self ->iter_children ($iter_parent);
        while ($child) {
            my $next = $self -> iter_next($child);
            $self -> remove($child);
            $child = $next; 
        };
    }
    
    # add new children
    my $items = $status->items ? $status->items->() : [];
    for my $i (@$items) {
        my $iter_child = $self->append($iter_parent);
        $self->set( $iter_child, 0 => $i );
    }
}

1;
