#!/usr/bin/env perl
use v5.14;
use utf8;
binmode STDOUT, ":utf8";
use Fcntl qw(SEEK_SET);

use URI;
use XML::Feed;
use IO::All;
use List::MoreUtils qw(uniq);
use Text::Util::Chinese qw(looks_like_simplified_chinese);

my @dirs = io->catfile(__FILE__)->absolute->splitdir();
splice @dirs, -2;

my $app_root = io->catdir(@dirs);

sub fetch_news_titles {
    my @titles;

    for my $topic (qw(t y w n b s e c m)) {
        my $uri = URI->new("http://news.google.com.tw/news?topic=${topic}&output=rss");
        my $feed = XML::Feed->parse($uri) or next;
        for my $entry ($feed->entries) {
            my $t = $entry->title
                =~ s/ - .+?$//r
                =~ s/$/。/r;

            utf8::decode($t) unless utf8::is_utf8($t);

            push @titles, $t;
        }
    }

    return @titles;
}

my $io = $app_root->catfile("corpus", "news.txt")->assert->utf8;
my @old_titles = $io->chomp->getlines;
my @new_titles = fetch_news_titles();

my @titles = sort { length($a) <=> length($b) } uniq
    grep {
        ! looks_like_simplified_chinese($_)
    } map {
        split /(?:\r?\n)+/
    }
    (@new_titles, @old_titles);

$io->seek(0, SEEK_SET);
$io->println($_) for @titles;
