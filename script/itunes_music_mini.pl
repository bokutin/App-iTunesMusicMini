#!/usr/bin/env perl

use utf8;
use Modern::Perl;

use rlib;
use App::iTunesMusicMini::Container qw(container);
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

    my %count;

    # playlist
    my @rel = do {
        my $itunes = Mac::iTunes->controller;
        my @abs = @{get_track_filenames_in_playlist($itunes,$config->get->{playlist_name})};
        @abs = grep { m/^@{[ $config->get->{itunes_media_music_main} ]}/ } @abs;
        map { File::Spec->abs2rel($_, $config->get->{itunes_media_music_main}) } @abs;
    };

    # copy
    for my $rel (@rel) {
        my $external = File::Spec->catfile($config->get->{itunes_media_music_main}, $rel);
        my $note     = File::Spec->catfile($config->get->{itunes_media_music_sub},  $rel);
        unless ( -f $note ) {
            my $dir = File::Spec->catdir((File::Spec->splitpath($note))[0,1]);
            unless ( -d $dir ) {
                make_path($dir) or die $!;
            }
            copy($external, $note) or die $!;
            $count{copied}++;
        }
    }

    # delete
    my @sub = map {
        $_->abs2rel($config->get->{itunes_media_music_sub});
    } grep { $_->filename !~ m/^\./ } io($config->get->{itunes_media_music_sub})->All_Files;
    my @needless = do {
        my %seen = map { uc($_) => 1 } @rel; # "Banco De Gaia" equal "Banco de Gaia".
        map { $seen{uc($_)} ? () : $_ } @sub;
    };
    for (@needless) {
        my $abs = File::Spec->catfile($config->get->{itunes_media_music_sub}, $_);
        say "REMOVE: " . $abs;
        unlink $abs;
        $count{deleted}++;
    }

    #
    say sprintf("items: %d, copied: %d, deleted: %d", 0+@rel, $count{copied}//0, $count{deleted}//0);
}

run();
