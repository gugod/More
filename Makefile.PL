#!/usr/bin/env perl
use ExtUtils::MakeMaker;

WriteMakefile(
    PREREQ_PM => {
        'Plack::Request' => 0.9974,
        'Dancer' => '1.2000',
        'Acme::DreamyImage' => '1.1',
        'Acme::Lingua::ZH::Remix' => '0.91',
        'Encode::HanConvert' => 0,
        'HTML::Entities' => 0,
        'HTML::TreeBuilder::Select' => 0,
        'List::MoreUtils' => 0,
        'Net::Twitter' => 0,
        'WWW::Mechanize' => 0,
        'XML::RSS' => 0,
        'YAML' => 0,
        'common::sense' => 0,
    }
);