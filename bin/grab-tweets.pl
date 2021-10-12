#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use utf8;

use Getopt::Long qw(GetOptions);

use IO::All;
use List::MoreUtils qw(uniq apply);
use Twitter::API;
use URI;
use XML::Feed;
use YAML;

my %opts;
GetOptions(
    \%opts,
    "config|c=s",
) or die("Unrecognised CLI options.");

($opts{config} && -f $opts{config}) or die "Need a config file";

my $config = YAML::LoadFile($opts{config}) or die "Failed to read the configuration file\n";

my @dirs = io->catfile(__FILE__)->absolute->splitdir();
splice @dirs, -2;

my $app_root = io->catdir(@dirs);

sub grab_tweets {
    my ($keyword) = @_;
    my $t = Twitter::API->new_with_traits(
        traits => 'Enchilada',
        consumer_key        => $config->{consumer_key},
        consumer_secret     => $config->{consumer_secret},
        access_token        => $config->{access_token},
        access_token_secret => $config->{access_token_secret},
    );

    my $r = $t->search( $keyword );

    return grep {
        !/(http|@\S+)/
    } map {
        $_->{text}
    } @{$r->{statuses}};
}

my @query = apply {
    utf8::decode($_) unless utf8::is_utf8($_);
} @ARGV;

die "Need some search terms.\n" unless @query;

my @new_tweets = map { grab_tweets($_) } @query;

my @old_tweets = $app_root->catfile("corpus", "tweets.txt")->assert->utf8->chomp->getlines;

my @tweets = sort { length($b) <=> length($a) } uniq apply {
    s/\s+/ /g;
    s/!+/！/g;
    s/\?+/？/g;
    s/,+/，/g;
} grep {
    /\p{Han}{6}/
} map {
    split /(?:\r?\n)+/
} (@new_tweets, @old_tweets);

my $out = $app_root->catfile("corpus", "tweets.txt")->utf8;
$out->println($_) for @tweets;
