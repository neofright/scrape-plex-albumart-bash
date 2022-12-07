#!/usr/bin/env bash
dependencies=("convert" "sqlite3") ## If you're using ImageMagick 7 then change "convert" to "magick"
for bin in "${dependencies[@]}"; do if ! command -v "$bin" >/dev/null 2>&1; then echo "ERROR: ${bin}(1) is required, but not installed."; deps=$((deps+1)); fi; done
if [[ "$deps" -ne 0 ]]; then echo "ERROR: Install the $deps missing dependencies and try again.";exit 1; fi

plex_dir="/mnt/scratch/plex/Library/Application Support/Plex Media Server"
plex_db="${plex_dir}/Plug-in Support/Databases/com.plexapp.plugins.library.db"

while IFS="|" read -r metadata_items_album_id metadata_items_album_hash metadata_items_album_thumb_url
do
    ## Some albums simply don't have artwork available, so we should skip them!
    if [[ -n "$metadata_items_album_thumb_url" ]]
    then
        ## Build the full path to the album art on disk...
        album_art_base_dir="${plex_dir}/Metadata/Albums/${metadata_items_album_hash:0:1}/${metadata_items_album_hash:1}.bundle/Contents/_combined"
        local_album_art="${album_art_base_dir}/${metadata_items_album_thumb_url#*/}"

        ## Get the first track id of this album
        ## Lookup the track's metadata_item_id and then retrieve the location of the track on disk
        child_id="$(sqlite3 "$plex_db" "SELECT id FROM metadata_items WHERE parent_id = '$metadata_items_album_id' LIMIT 1")"
        track_media_id="$(sqlite3 "$plex_db" "SELECT id FROM media_items WHERE metadata_item_id = '$child_id'")"
        track_file="$(sqlite3 "$plex_db" "SELECT file FROM media_parts WHERE media_item_id = '$track_media_id'")"

        ## The album directory is where the track file is stored
        album_dir="$(dirname "$track_file")"

        ## I don't want to store the album art in the original directory tree, so I do path substitution here
        album_dir_replaced="${album_dir//\/mnt\/Music\//\/mnt\/tank\/data\/Music\/Album Art\/}"
        mkdir -p "${album_dir_replaced}"
        
        destination_file="${album_dir_replaced}/folder.jpg"
        ## If we haven't already scraped this album's art...
        if [[ ! -f "$destination_file" ]]
        then
            ## - Convert the file format to jpeg if it is in another format.
            ## - Resize the album art. This is being used on an iPod (the display is 320x320).
            ## - Rockbox doesn't support progressive scan jpegs, so we must convert the image.
            ## https://stackoverflow.com/questions/14556984/imagemagick-creating-multiple-files
            printf "Converting and resizing %s..." "$destination_file"
            convert "$local_album_art"[0] -resize 320x320 -interlace none "$destination_file" 2>/dev/null && \
            printf "OK\n" || \
            printf "ERR\n"
        fi
    fi
done < <(sqlite3 "$plex_db" "SELECT id,hash,user_thumb_url FROM metadata_items WHERE metadata_type = '9' AND library_section_id != '10'")
