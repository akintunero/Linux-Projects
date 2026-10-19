#!/usr/bin/env bash
# Day 10 medium: dry-run plan for renaming camera photos. Nothing is renamed.
set -euo pipefail

photos=("IMG 0042.JPG" "Holiday  Beach.JPEG" "IMG_7.png")

for old in "${photos[@]}"; do
    new="${old,,}"            # lowercase
    new="${new//  /-}"        # double spaces to a dash
    new="${new// /-}"         # single spaces to a dash
    new="${new//_/-}"         # underscores to a dash
    if [[ $new == *.jpeg ]]; then
        new="${new%.jpeg}.jpg"   # normalise .jpeg to .jpg
    fi
    printf '%-22s -> %s\n' "$old" "$new"
done
