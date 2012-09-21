package App::iTunesMusicMini::Container;

use strict;
use warnings;

use Object::Container '-base';

use Class::Load ':all';
use File::Spec::Functions ":ALL";

register "config" => sub {
    my $class = "App::iTunesMusicMini::Config";

    load_class($class);
    my $level = split(/::/, $class);
    my $path_to = catdir( (splitpath(__FILE__))[1], join("/", map { ".." } (1..$level)) );
    $class->new( name => "app_itunesmusicmini", path_to => $path_to, path => File::Spec->catdir($path_to, "etc") );
};

1;
