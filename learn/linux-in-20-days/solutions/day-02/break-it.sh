#!/usr/bin/env bash
# Day 02 - Break it (BUGGY on purpose). Run it inside an empty scratch directory.
# Goal: back up the folder "my photos" to backup/2024 and remove *.tmp files in it.
set -e
src="my photos"
dest=backup/2024

mkdir -p "$src"; touch "$src/a.jpg" "$src/b.jpg"

mkdir $dest
cp -r $src $dest
rm $src/*.tmp
echo "backup complete"
