package App::PerlWatcher::UI::Gtk2::URLOpener;
{
  $App::PerlWatcher::UI::Gtk2::URLOpener::VERSION = '0.09';
}
# ABSTRACT: The class is responsible for opening urls after a shord idle.

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Moo;
use Scalar::Util qw/weaken/;



has 'openables'  => ( is => 'rw', default => sub{ []; } );


has 'timer' => (is => 'rw');


has 'delay' => (is => 'rw', required => 1);


has 'callback' => (is => 'rw', required => 1);


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

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::Gtk2::URLOpener - The class is responsible for opening urls after a shord idle.

=head1 VERSION

version 0.09

=head1 DESCRIPTION

The more detailed description of PerlWatcher application can be found here:
L<https://github.com/basiliscos/perl-watcher>.

=head1 ATTRIBUTES

=head2 openables

The list of objects been opened in browser

=head2 timer

AE timer object, which will open all openables on timeout

=head2 delay

The timeout which should pass after delayed_open is been invoked
to open all openables.

=head2 callback

Callback is been invoked when timer triggers. It's arguments
is the array ref openables.

=head1 METHODS

=head2 delayed_open

Puts the openable into queue and resets the timer. When
timer triggers all openables are open and erased from list

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
