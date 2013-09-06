#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Test::More;

use aliased qw/App::PerlWatcher::UI::Gtk2::URLOpener/;

sub tick {
    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->idle (cb => sub { $cv->send });
    $cv->recv;
}

my @opened_urls;

my $callback = sub {
    my $opened_items = shift;
    @opened_urls = map { $_->url } @$opened_items;
};

package Test::PerlWatcher::TestOpenable {
    use Moo;

    with 'App::PerlWatcher::Openable';
    sub open_url { }
};

my $uo = URLOpener->new(
    delay    => 0,
    callback => $callback,
);

ok $uo, "instance has been created";

{
    $uo->delayed_open(
        Test::PerlWatcher::TestOpenable->new( url => 'a')
      );
    tick;
    is_deeply \@opened_urls, ["a"] ;
};

{
    @opened_urls = ();
    $uo->delayed_open(
        Test::PerlWatcher::TestOpenable->new( url => 'b')
      );
    $uo->delayed_open(
        Test::PerlWatcher::TestOpenable->new( url => 'c')
      );
    tick;
    is_deeply [sort @opened_urls], ["b", "c"];
};

{
    @opened_urls = ();
    $uo->delay(2);
    $uo->delayed_open(
        Test::PerlWatcher::TestOpenable->new( url => 'd')
    );
    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer (after=> 1, cb => sub { $cv->send });
    $cv->recv;
    is scalar @opened_urls, 0, "no event yet";
    $uo->delayed_open(
        Test::PerlWatcher::TestOpenable->new( url => 'e')
    );
    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer (after=> 2, cb => sub { $cv->send });
    $cv->recv;
    tick;
    is_deeply [sort @opened_urls], ["d", "e"];
};

done_testing;
