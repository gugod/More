package More;
use Dancer ':syntax';
our $VERSION = '1.0';

use utf8;
use strict;

use Acme::Lingua::ZH::Remix;
use Acme::DreamyImage;
use Encode qw(encode_utf8);
use String::Trim qw(trim);
use XML::RSS;

my %remixer = ();
{
    for my $corpus_file (<corpus/*.txt>) {
        open(FH, "<:utf8", $corpus_file);

        my %lines;
        while (my $line = <FH>) {
            trim($line);
            $line =~ s/\A\p{Other_Punctuation}//;
            next if $line =~ /\A\s*\z/;

            if ($line !~ /\p{Punct}\z/) {
                for my $p ("、", "，", "。", "；") {
                    $lines{$line . $p} = 1;
                }
            } else {
                $lines{$line} = 1;
            }
        }
        my $text = join "\n", keys %lines;

        my $remixer = Acme::Lingua::ZH::Remix->new(phrases => {});
        $remixer->feed($text);

        my $name = $corpus_file;
        $name =~ s/\.txt$//;
        $name =~ s/^corpus\///;

        $remixer{$name} = $remixer;
    }
}

sub random_sentences {
    my ($n, $corpus, $min, $max) = @_;
    my @sentences;

    if ($corpus) {
        my $remixer = $remixer{$corpus};
        for (1..$n) {
            my $s = $remixer->random_sentence(min => $min, max => $max);
            push @sentences, $s;
        }
    }
    else {
        my @corpus = keys %remixer;
        for (1..$n) {
            my $remixer = $remixer{ $corpus[int(rand() * @corpus)] };
            my $s = $remixer->random_sentence(min => $min, max => $max);
            push @sentences, $s;
        }
    }
    return @sentences;
}

get '/' => sub {
    template 'index';
};

get '/api' => sub {
    template 'api';
};

get '/leanback' => sub {
    template 'leanback', {}, { layout => undef };
};

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

    my @sentences = random_sentences($n, $corpus, $min, $max);

    my $json_text = to_json({ sentences => \@sentences });
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

    my $rss = XML::RSS->new(version => '2.0', encoding => "UTF-8");
    $rss->channel(
        title => "MoreText",
        link  => "http://more.handlino.com",
        description => "The Chinese Lipsum generator you love."
    );

    for my $remixer (values %remixer) {
        $rss->add_item(
            title       => $remixer->random_sentence(max => 42),
            description => join "\n\n", map { $remixer->random_sentence } 1..4,
        );
    }

    return encode_utf8($rss->as_string);
};

# */image/random/256x256jpg
get '/image/:seed/:size.jpg' => sub {
    my $params = shift;
    pass unless (params->{size} =~ /^[1-9][0-9]+x[1-9][0-9]+$/);

    my $seed = params->{seed};
    pass unless $seed eq '*' || $seed =~ /^[0-9a-f]+$/;
    $seed = (time() . rand()) if $seed eq '*';

    my ($width, $height) = split "x", params->{size};
    pass unless $width <= 1024 && $height <= 1024;

    my $blob;
    Acme::DreamyImage
        ->new( seed => $seed,
               width  => 384,
               height => 384 )
        ->random_image()
        ->scale( xpixels => $width,
                 ypixels => $height )
        ->crop( top => 0, left => 0,
                width => $width, height => $height )
        ->write( data => \$blob,
                 type => "jpeg" );


    content_type 'jpg';
    return $blob;
};

true;
