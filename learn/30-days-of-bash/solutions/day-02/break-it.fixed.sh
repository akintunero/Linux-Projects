#!/usr/bin/env bash
# Fixed: quote the file name, and guard the glob so "no .log files" is not an error.
mkdir -p backup archive
echo "hello" > "my notes.txt"
cp "my notes.txt" backup/

shopt -s nullglob
logs=(*.log)
if (( ${#logs[@]} > 0 )); then
    mv -- "${logs[@]}" archive/
fi
ls backup archive
