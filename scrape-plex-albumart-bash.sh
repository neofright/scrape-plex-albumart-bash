#!/usr/bin/env bash
## If you're using ImageMagick 7 then change this check to look for "magick(1)"
command -v convert >/dev/null 2>&1 || { echo >&2 "convert(1) is required, but not installed. Aborting."; exit 1; };

plex_dir="/mnt/scratch/plex/Library/Application Support/Plex Media Server"
plex_db="${plex_dir}/Plug-in Support/Databases/com.plexapp.plugins.library.db"

while read -r metadata_items_album
do
    ## Split the id and hash values from the '|' separated sqlite3 response...
    metadata_items_album_id="$(echo "$metadata_items_album"|cut -f1 -d'|')"
    metadata_items_album_hash="$(echo "$metadata_items_album"|cut -f2 -d'|')"

    ## Build the full path to the album art on disk...
    album_art_base_dir="${plex_dir}/Metadata/Albums/${metadata_items_album_hash:0:1}/${metadata_items_album_hash:1}.bundle/Contents/_combined"
    album_thumb_url="$(sqlite3 "$plex_db" "SELECT thumb_url FROM taggings WHERE metadata_item_id = '$metadata_items_album_id' AND thumb_url LIKE '%music%'")"

    ## Some albums simply don't have artwork available, so we should skip them!
    if [[ -n "$album_thumb_url" ]]
    then 
        local_album_art="${album_art_base_dir}/${album_thumb_url//metadata:\/\//}"

        ## Get all of the track ids of this album and then use head to select just a single track
        ## Lookup the track's metadata_item_id and then retrieve the location of the track on disk
        child_id="$(sqlite3 "$plex_db" "SELECT id FROM metadata_items WHERE parent_id = '$metadata_items_album_id'"|head -n1)"
        track_media_id="$(sqlite3 "$plex_db" "SELECT id FROM media_items WHERE metadata_item_id = '$child_id'")"
        track_file="$(sqlite3 "$plex_db" "SELECT file FROM media_parts WHERE media_item_id = '$track_media_id'")"

        ## The album directory is where the track file is stored
        album_dir="$(dirname "$track_file")"

        ## I don't want to store the album art in the original directory tree, so I do path substitution here
        album_dir_replaced="${album_dir//\/mnt\/Music\//\/mnt\/tank\/data\/Music\/Album Art\/}"
        mkdir -p "${album_dir_replaced}"

        #user_thumb_url="$(sqlite3 "$plex_db" "SELECT user_thumb_url FROM metadata_items WHERE id = '$metadata_items_album_id'")"
        
        destination_file="${album_dir_replaced}/folder.jpg"
        ## If we haven't already scraped this album's art...
        if [[ ! -f "$destination_file" ]]
        then
            ## - Convert the file format to jpeg if it is in another format.
            ## - Resize the album art. This is being used on an iPod (the display is 320x320).
            ## - Rockbox doesn't support progressive scan jpegs, so we must convert the image.
            ## https://stackoverflow.com/questions/14556984/imagemagick-creating-multiple-files
            printf "Converting and resizing %s..." "$destination_file"
            convert "$local_album_art"[0] -resize 320x320 -interlace none "$destination_file" && \
            printf "OK\n"
        fi
    fi
done < <(sqlite3 "$plex_db" "SELECT id,hash FROM metadata_items WHERE metadata_type = '9' AND library_section_id != '10'")
