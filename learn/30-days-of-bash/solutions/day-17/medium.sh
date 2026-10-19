#!/usr/bin/env bash
# Day 17 medium: batch-rename photos to holiday-001.jpg, holiday-002.jpg ... with a dry-run switch.
# Temporary files only.
set -euo pipefail

rename_photos() {
    local dir="$1" dry_run="$2" n=0 path new
    while IFS= read -r -d '' path; do
        n=$(( n + 1 ))
        new="$(printf '%s/holiday-%03d.jpg' "$dir" "$n")"
        if (( dry_run )); then
            echo "would rename: ${path##*/} -> ${new##*/}"
        else
            mv -n -- "$path" "$new"
            echo "renamed:      ${path##*/} -> ${new##*/}"
        fi
    done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | sort -z)
    echo "${n} file(s) processed"
}

work="$(mktemp -d)"
touch "${work}/IMG 001.JPG" "${work}/IMG 002.JPG" "${work}/img 10.jpeg" "${work}/notes.txt"

rename_photos "$work" 1
echo "--- real run"
rename_photos "$work" 0
echo "--- result"
ls "$work"

rm -rf -- "$work"
