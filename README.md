# scrape-plex-albumart-bash

I needed a way to get accurate album art for Rockbox on my iPod 6g. My library is indexed in Plex and the albumart scraping is more reliable than any other tool I have found.

I did this initially in Python [here](https://github.com/neofright/scrape-plex-albumart) using the plexapi module and it worked well.

However, because my Plex account uses 2FA there was no easy way to run the script periodically with cron.

Because of this, I decided to read the Plex database directly instead.

Some direction was provided by [bullwinkle’s how to title titles, or, sqlite in plex for fun and panic](https://wonkabar.org/bullwinkles-how-to-title-titles-or-sqlite-in-plex-for-fun-and-panic/).

## Usage:
Edit the contents of the variable:

    $plex_dir

## Behaviour:
By default, the script will place a `folder.jpg` in every album's directory if it doesn't already exist.

(Plex artwork is converted to jpeg, resized to 320x320 and set to interlaced.)

- If you wish to copy the existing artwork without conversion set `convert=0`.

- If you wish to do path substitution then look at the `*_path_substitution` variables.



## Requirements:
    ImageMagick (convert)
    sqlite3

**Note** that your Music library name(s) must contain the string 'Music' e.g. `Music` or `DnB Music` etc.