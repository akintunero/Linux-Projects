#!/usr/bin/env bash
# Day 05 easy: print a numbered list of JPEG files; say so if there are none.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
touch "beach day.jpg" city.jpg notes.txt forest.jpg

n=0
for photo in *.jpg; do
    n=$(( n + 1 ))
    echo "${n}: ${photo}"
done
if (( n == 0 )); then
    echo "No JPEG files"
fi

cd / && rm -rf -- "$work"
