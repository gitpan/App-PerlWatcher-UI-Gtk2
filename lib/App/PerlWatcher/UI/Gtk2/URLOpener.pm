package App::PerlWatcher::UI::Gtk2::URLOpener;
{
  $App::PerlWatcher::UI::Gtk2::URLOpener::VERSION = '0.07_1';
}
# ABSTRACT: The class is responsible for opening urls after a shord idle.

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Moo;
use Scalar::Util qw/weaken/;

=head1 DESCRIPTION

The more detailed description of PerlWatcher application can be found here:
L<https://github.com/basiliscos/perl-watcher>.

=cut

=attr openables

The list of objects been opened in browser

=cut

has 'openables'  => ( is => 'rw', default => sub{ []; } );

=attr timer

AE timer object, which will open all openables on timeout

=cut

has 'timer' => (is => 'rw');

=attr delay

The timeout which should pass after delayed_open is been invoked
to open all openables.

=cut

has 'delay' => (is => 'rw', required => 1);

=attr callback

Callback is been invoked when timer triggers. It's arguments
is the array ref openables.

=cut

has 'callback' => (is => 'rw', required => 1);

=method delayed_open

Puts the openable into queue and resets the timer. When
timer triggers all openables are open and erased from list

=cut

sub delayed_open {
    my ($self, $openable) = @_;
    push @{ $self->openables }, $openable;

    weaken $self;
    $self->timer(
        AnyEvent->timer(
            after => $self->delay,
            cb => sub {
                my $openables = $self->openables;
                $_->open_url for( @$openables );
                $self->openables([]);
                $self->callback->($openables);
            }
        )
    );
}

1;
