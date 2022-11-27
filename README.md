# scrape-plex-albumart-bash

I needed a way to get accurate album art for Rockbox on my iPod 6g. Seeing as I already had my library indexed in Plex and the albumart scraping has been very reliable I decided to export the album art this way.

I did this initially in Python [here](https://github.com/neofright/scrape-plex-albumart) using the plexapi module and it worked well.

However because my Plex account uses 2FA there was no easy way to run the script periodically with cron.

Because of this, I decided that I could probably read the Plex database directly and copy files directly on my server.

This script will probably make some people barf, and I am not a DBA, so it certainly can be optimised beyond its current state.

With that said, it works just fine.

## Usage:
Edit the contents of these variables:

    $plex_dir
    $album_dir_replaced

Note that I had to exclude my "Audio Books" Music library (library_section_id '10') so if your music library has id 10 for some reason you'll need to edit the script.

## Requirements:
ImageMagick (convert)
sqlite3