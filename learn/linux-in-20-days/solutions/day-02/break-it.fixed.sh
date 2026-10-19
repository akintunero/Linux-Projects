#!/usr/bin/env bash
# Day 02 - Break it, fixed. Bugs were:
#   1. `mkdir $dest` fails because backup/ does not exist -> use mkdir -p.
#   2. `cp -r $src $dest` splits "my photos" into two words -> quote both variables.
#   3. `rm $src/*.tmp` fails (glob matches nothing, rm errors, set -e aborts) -> use find -delete.
# Safe: runs in a temporary directory.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

src="my photos"
dest=backup/2024

mkdir -p "$src"; touch "$src/a.jpg" "$src/b.jpg"

mkdir -p "$dest"
cp -r "$src" "$dest"
find "$src" -name '*.tmp' -type f -delete
echo "backup complete"

[[ -f "$dest/my photos/a.jpg" ]] || { echo "FAIL: copy missing" >&2; exit 1; }
echo PASS >&2
