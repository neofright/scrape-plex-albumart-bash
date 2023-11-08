#!/usr/bin/env bash
dependencies=("convert" "sqlite3") ## If you're using ImageMagick 7 then change "convert" to "magick"
for bin in "${dependencies[@]}"; do if ! command -v "$bin" >/dev/null 2>&1; then echo "ERROR: ${bin}(1) is required, but not installed."; deps=$((deps+1)); fi; done
if [[ "$deps" -ne 0 ]]; then echo "ERROR: Install the $deps missing dependencies and try again.";exit 1; fi

scrape_plex_album_art()
{
    library_section_id="$1"
    while IFS="|" read -r metadata_items_album_id metadata_items_album_hash metadata_items_album_thumb_url
    do
        ## Build the full path to the album art on disk...
        album_art_base_dir="${plex_dir}/Metadata/Albums/${metadata_items_album_hash:0:1}/${metadata_items_album_hash:1}.bundle/Contents/_combined"
        local_album_art="${album_art_base_dir}/${metadata_items_album_thumb_url#*/}"

        ## Get the file location of this album's first track
        track_file="$(sqlite3 "$plex_db" "SELECT media_parts.file FROM metadata_items JOIN media_items ON media_items.metadata_item_id = metadata_items.id JOIN media_parts ON media_parts.media_item_id = media_items.id WHERE metadata_items.parent_id = '$metadata_items_album_id' LIMIT 1;")"
        album_dir="$(dirname "$track_file")" ## The album directory is where the track file is stored

        ## If we don't want to store the album art in the original directory tree, do path substitution here.
        # shellcheck disable=SC2154
        if [[ "${#plex_music_library_db_path_substitution[@]}" -eq 1 ]]; then album_dir="${album_dir//${!plex_music_library_db_path_substitution[@]}/${plex_music_library_db_path_substitution[@]}}" && mkdir -p "${album_dir}"; fi
        
        if [[ "$convert" == 0 ]]
        then
            destination_file="${album_dir}/folder.$(file --brief --extension "$local_album_art"|cut -f1 -d'/'|sed 's/jpeg/jpg/')"
            if [[ ! -f "$destination_file" ]]; then printf "Copying %s..." "$destination_file";cp "$local_album_art" "$destination_file" 2>/dev/null && printf "OK\n" || printf "ERR\n";fi
        else
            destination_file="${album_dir}/${album_art_jpeg_filename}"
            if [[ ! -f "$destination_file" ]]; then printf "Converting and resizing %s..." "$destination_file";convert "$local_album_art"[0] -resize 136x136 -interlace none "$destination_file" 2>/dev/null && printf "OK\n" || printf "ERR\n";fi
        fi

    done < <(sqlite3 "$plex_db" "SELECT id,hash,user_thumb_url FROM metadata_items WHERE metadata_type = '9' AND user_thumb_url != '' AND library_section_id = '$library_section_id'")
}

## If you rename or delete an album in your source directory, the previously scraped (path substituted) album art
## will still exist and should be deleted...
tidy_substituted_album_art_directory()
{
    ## Only do this if you're actually using path substitution...
    if [[ "${#album_art_path_substitution[@]}" -eq 1 ]]
    then
        echo "Searching for path substituted album art to delete..."
        while IFS='' read -r -d '' album_art_image
        do
            album_art_dir="$(dirname "$album_art_image")"
            album_dir="${album_art_dir//${album_art_path_substitution[@]}/${!album_art_path_substitution[@]}}"

            if [[ ! -d "$album_dir" && -d "$album_art_dir" ]];
            then
                ## This feels safer than issuing "rm -rfv"
                rm -v "${album_art_dir}/${album_art_jpeg_filename}" && rmdir -v "$album_art_dir"
            fi
        done < <(find "${album_art_path_substitution[@]}" -type f -name "$album_art_jpeg_filename" -print0)
    fi
}

album_art_jpeg_filename="folder.jpg"
plex_dir="/mnt/scratch/plex/Library/Application Support/Plex Media Server"
plex_db="${plex_dir}/Plug-in Support/Databases/com.plexapp.plugins.library.db"
convert=1

## Note when doing path substitution that this is done to ALL music libraries and ALL library sections (paths).
## With multiple libraries and/or multiple library sections with different root paths (e.g. '/mnt/Music' '/media/Music'), this won't work well for you.
## I expect that most users don't want to do path subsitution and because it is difficult to account for I will not expand this functionality.
#declare -A plex_music_library_db_path_substitution
#plex_music_library_db_path_substitution[""]=""

## You might not want to save the album art alongside the original tracks.
# declare -A album_art_path_substitution
# album_art_path_substitution["/mnt/tank/data/Music"]="/mnt/tank/data/Music/Album Art"

while IFS="|" read -r library_id library_name
do
    printf "Scraping artwork from Plex library '%s'...\n" "$library_name"
    scrape_plex_album_art "$library_id"
done < <(sqlite3 "$plex_db" "SELECT id,name FROM library_sections WHERE name LIKE '%Music%' AND section_type = '8'") ## Your Plex library name must contain the string "Music".

tidy_substituted_album_art_directory
