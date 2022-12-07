# scrape-plex-albumart-bash

I needed a way to get accurate album art for Rockbox on my iPod 6g. Seeing as I already had my library indexed in Plex and the albumart scraping has been very reliable I decided to export the album art this way.

I did this initially in Python [here](https://github.com/neofright/scrape-plex-albumart) using the plexapi module and it worked well.

However because my Plex account uses 2FA there was no easy way to run the script periodically with cron.

Because of this, I decided that I could probably read the Plex database directly on my server instead.

## Usage:
Edit the contents of these variables:

    $plex_dir
    $album_dir_replaced

Note that your Music library name(s) must contain the string 'Music' e.g. `Music` or `DnB Music` etc.

Some direction was provided by [bullwinkle’s how to title titles, or, sqlite in plex for fun and panic](https://wonkabar.org/bullwinkles-how-to-title-titles-or-sqlite-in-plex-for-fun-and-panic/).

## Requirements:
ImageMagick (convert)

sqlite3