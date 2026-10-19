#!/usr/bin/env bash
# Day 02 easy: build the photo tree and list only the .jpg files.
work="$(mktemp -d)"
cd "$work" || exit 1

mkdir -p photos/{2024,2025}
touch photos/2024/{beach,city}.jpg photos/2024/notes.txt
touch photos/2025/{forest,lake}.jpg photos/2025/edit.png

echo "JPEG files:"
ls photos/*/*.jpg

cd / && rm -rf -- "$work"
