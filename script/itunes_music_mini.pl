#!/usr/bin/env perl

use utf8;
use Modern::Perl;

use rlib;
use App::iTunesMusicMini::Container qw(container);
#use Encode;
#use Encode::UTF8Mac;
use File::Copy;
use File::Path qw(make_path);
use IO::All;
use Mac::iTunes;

# Mac::iTunes::AppleScript::get_track_names_in_playlist を元にちょっと変更。
sub get_track_filenames_in_playlist {
    my ($self, $playlist) = @_;

    $playlist = $self->_escape_quotes($playlist);

    my $script =<<"SCRIPT";
    set myPlaylist to "$playlist"
    set myString to ""
    repeat with i from 1 to count of tracks in playlist myPlaylist
        set thisLocation to location of file track i in playlist myPlaylist
        set myString to myString & POSIX path of thisLocation & return
    end repeat
    return myString
SCRIPT

    my $result = $self->tell( $script );

    my @list = split /\015/, $result;

    #local $" = " <-> ";
    #print STDERR "Found " . @list . " items [@list]\n";
    return \@list;
}

sub run {
    my $config = container('config');

    #binmode STDOUT, ":utf8";

    my $itunes = Mac::iTunes->controller;

    my %seen;

    my @files = @{get_track_filenames_in_playlist($itunes,$config->get->{playlist_name})};
    @files = grep { m/^@{[ $config->get->{itunes_media_music_main} ]}/ } @files;
    #say 0+@files;
    #@files = map { Encode::decode('utf-8-mac', $_) } @files;
    for my $file1 (@files) {
        my $file2 = File::Spec->catfile($config->get->{itunes_media_music_sub}, File::Spec->abs2rel($file1, $config->get->{itunes_media_music_main}));
        unless ( -f $file2 ) {
            my $dir = File::Spec->catdir((File::Spec->splitpath($file2))[0,1]);
            unless ( -d $dir ) {
                make_path($dir) or die $!;
            }
            copy($file1, $file2) or die $!;
        }
        $seen{$file2} = 1;
    }

    for my $file (io($config->get->{itunes_media_music_sub})->All_Files) {
        next if $file->filename =~ m/^\./;
        unless ( $seen{$file} ) {
            say "REMOVE: " . $file->pathname;
        }
    }
}

run();
