package More;
use Dancer ':syntax';
our $VERSION = '1.0';

use strict;

use Acme::Lingua::ZH::Remix 0.95;
use Encode qw(encode_utf8 decode_utf8);
use XML::RSS;

get '/' => sub {
    template 'index';
};

get '/api' => sub {
    template 'api';
};

get '/leanback' => sub {
    template 'leanback', {}, { layout => undef };
};

my %remixer = ();
{
    for my $corpus_file (<corpus/*.txt>) {
        open(FH, "<:utf8", $corpus_file);
        local $/ = undef;
        my $text = <FH>;
        close(FH);

        my $remixer = Acme::Lingua::ZH::Remix->new(phrases => {});
        $remixer->feed($text);

        my $name = $corpus_file;
        $name =~ s/\.txt$//;
        $name =~ s/^corpus\///;

        $remixer{$name} = $remixer;
    }
}
my @corpus = keys %remixer;

get '/sentences.json' => sub {
    my $self = shift;
    my $cb = params->{callback};
    my $n  = params->{n} || 1;
    $n = 1 if $n > 100;

    my $corpus = params->{corpus};
    my $remixer = $corpus ? $remixer{$corpus} : undef;

    my ($min, $max) = split(",", params->{limit}||"0,140");
    if ($min && !$max) {
        ($min, $max) = (0, $min);
    }

    $min = 0   if $min < 0;
    $max = 500 if $max > 500;

    my @sentences;
    for(1..$n) {
        unless ($corpus) {
            $remixer = $remixer{ $corpus[int(rand() * @corpus)] };
        }

        my $s = $remixer->random_sentence(min => $min, max => $max);
        push @sentences, $s;
    }

    my $json_text = decode_utf8+to_json({ sentences => \@sentences });

    if ($cb) {
        content_type 'application/javascript';
    }
    else {
        content_type 'application/json'
    }

    return $cb ? "${cb}(${json_text})" : $json_text;
};

get '/sentences.rss' => sub {
    content_type 'application/rss+xml';

    my $self = shift;

    my $rss = XML::RSS->new(version => '1.0', encoding => "utf8");
    $rss->channel(
        title => "MoreText",
        link  => "http://more.handlino.com",
        description => "The Chinese Lipsum generator you love."
    );

    for my $remixer (values %remixer) {
        $rss->add_item(
            title       => $remixer->random_sentence,
            link        => "http://more.handlino.com",
            description => join "", map { $remixer->random_sentence } 1..3,
        );
    }

    return encode_utf8($rss->as_string);
};

true;
