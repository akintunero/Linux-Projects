#!/usr/bin/env bash
# Day 02 medium: sort a messy folder into docs/ and logs/. Safe to re-run.
work="$(mktemp -d)"
cd "$work" || exit 1
touch a.txt b.txt "my notes.txt" c.log d.csv

mkdir -p docs logs
shopt -s nullglob          # a pattern with no match expands to nothing, not to itself

txt=(*.txt)
logs=(*.log)

if (( ${#txt[@]} > 0 )); then
    mv -v -- "${txt[@]}" docs/
fi
if (( ${#logs[@]} > 0 )); then
    mv -v -- "${logs[@]}" logs/
fi

echo "--- result"
find . -type f | sort

cd / && rm -rf -- "$work"
