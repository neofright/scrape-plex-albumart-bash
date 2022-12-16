#!/usr/bin/env bash
dependencies=("convert" "sqlite3") ## If you're using ImageMagick 7 then change "convert" to "magick"
for bin in "${dependencies[@]}"; do if ! command -v "$bin" >/dev/null 2>&1; then echo "ERROR: ${bin}(1) is required, but not installed."; deps=$((deps+1)); fi; done
if [[ "$deps" -ne 0 ]]; then echo "ERROR: Install the $deps missing dependencies and try again.";exit 1; fi

function scrape_plex_album_art()
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
        if [[ "${#global_music_library_path_substitution[@]}" -eq 1 ]]; then album_dir="${album_dir//${!global_music_library_path_substitution[@]}/${global_music_library_path_substitution[@]}}" && mkdir -p "${album_dir}"; fi
        
        if [[ "$convert" == 0 ]]
        then
            destination_file="${album_dir}/folder.$(file --extension "$local_album_art"|cut -f1 -d'/')"
            if [[ ! -f "$destination_file" ]]; then printf "Copying %s..." "$destination_file";cp "$local_album_art" "$destination_file" 2>/dev/null && printf "OK\n" || printf "ERR\n";fi
        else
            destination_file="${album_dir}/folder.jpg"
            if [[ ! -f "$destination_file" ]]; then printf "Converting and resizing %s..." "$destination_file";convert "$local_album_art"[0] -resize 320x320 -interlace none "$destination_file" 2>/dev/null && printf "OK\n" || printf "ERR\n";fi
        fi

    done < <(sqlite3 "$plex_db" "SELECT id,hash,user_thumb_url FROM metadata_items WHERE metadata_type = '9' AND user_thumb_url != '' AND library_section_id = '$library_section_id'")
}

plex_dir="/mnt/scratch/plex/Library/Application Support/Plex Media Server"
plex_db="${plex_dir}/Plug-in Support/Databases/com.plexapp.plugins.library.db"
convert=1

## Note when doing path substitution that this is done to ALL music libraries and ALL library sections (paths).
## With multiple libraries and/or multiple library sections with different root paths (e.g. '/mnt/Music' '/media/Music'), this won't work well for you.
## I expect that most users don't want to do path subsitution and because it is difficult to account for I will not expand this functionality.
#declare -A global_music_library_path_substitution
#global_music_library_path_substitution["/mnt/Music"]="/mnt/tank/data/Music/Album Art"

while IFS="|" read -r library_id library_name
do
    printf "Scraping artwork from Plex library '%s'...\n" "$library_name"
    scrape_plex_album_art "$library_id"
done < <(sqlite3 "$plex_db" "SELECT id,name FROM library_sections WHERE name LIKE '%Music%' AND section_type = '8'") ## Your Plex library name must contain the string "Music".