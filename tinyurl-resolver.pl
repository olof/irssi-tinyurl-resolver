#!/usr/bin/perl
# Copyright 2009-2011, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without 
# modification, are permitted in any medium without royalty 
# provided the copyright notice are preserved. This file is 
# offered as-is, without any warranty.

use strict;
use LWP::UserAgent;
use Irssi;

my $VERSION = '0.51';
my %IRSSI = (
	authors     => "Olof 'zibri' Johansson",
	contact     => 'olof@ethup.se',
	name        => 'tinyurl-resolver',
	description => 'Make long URI of tinyurl (et al) links (i.e. resolve)',
	license     => 'GNU APL',
);

my $debug = 1;

my @tinyfiers;
add_domain('tinyurl.com');
add_domain('bit.ly');
add_domain('cot.ag');
add_domain('ow.ly');
add_domain('goo.gl');
add_domain('tiny.cc');
add_domain('t.co');
add_domain('gaa.st');
add_domain('wth.se');
add_domain('korta.nu');

# 2011-05-23, 0.51:
# * Fixed the irssi color code bug
# 2011-05-22, 0.5:
# * Rewrote to use LWP::UserAgent instead of sockets
# * Case insensitive matching on URL
# * Added wth.se
# 2011-02-13, 0.4:
# * added support for multiple url shortening services
# * changed license to GNU APL

# This started of as a modified version of youtube-title.pl 
# See also:
# * http://www.stdlib.se/
# * https://github.com/olof/hacks/tree/master/irssi

Irssi::signal_add("message public", \&handler);
Irssi::signal_add("message private", \&handler);

sub wprint {
	my $server = shift;
	my $target = shift;
	my $msg = join '', @_;

	my $win = $server->window_item_find($target);
	$win->print($msg, MSGLEVEL_CLIENTCRAP);
}

sub resolution {
	my $server = shift;
	my $target = shift;
	my $tiny = shift;
	my $dest = shift;

	wprint($server, $target, "%y$tiny -> $dest");
}


sub add_domain {
	my $domain = shift;
	my $suffix = shift // qr{/\w+};
	my $prefix = shift // qr{(?:http://(?:www\.)?|www\.)};

	push @tinyfiers, qr/$prefix \Q$domain\E $suffix/x;
}


sub hastiny {
	my($msg) = @_;

	foreach(@tinyfiers) {
		if(my($url) = $msg =~ /($_)/i) {
			if($url =~ /^www/i) {
				return "http://$url";
			}

			return $url;
		}
	}

	return;
}

sub handler {
	my($server, $msg, $nick, $address, $target) = @_;
	$target = $nick unless defined $target;

	while(my $url = hastiny($msg)) {
		my $loc = get_location($url);

		$url =~ s/%/%%/g;
		$loc =~ s/%/%%/g;
		
		if($loc) {
			resolution($server, $target, $url, $loc);
		} elsif($debug) {
			wprint($server, $target, "%y$url:%n invalid link");
		}

		$msg =~ s/$url//;
	}
}

sub get_location {
	my ($url) = @_;
	
	my $ua = LWP::UserAgent->new(
		max_redirect => 0,
	);

	$ua->agent("$IRSSI{name}/$VERSION (irssi)");
	$ua->timeout(3);
	$ua->env_proxy;

	my $response = $ua->head($url);

	return $response->header('location'); 
}

