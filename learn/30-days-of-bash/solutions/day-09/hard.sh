#!/usr/bin/env bash
# Day 09 hard: group the files of a directory by extension.
# Works on a temporary directory only.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
touch a.txt b.txt c.jpg d.jpg e.jpg Makefile notes.md "my doc.txt"

declare -A count names
for f in *; do
    [[ -f $f ]] || continue
    if [[ $f == *.* ]]; then
        ext="${f##*.}"
    else
        ext="(none)"
    fi
    count[$ext]=$(( ${count[$ext]:-0} + 1 ))
    names[$ext]+="${f}, "
done

mapfile -t exts <<< "$(printf '%s\n' "${!count[@]}" | sort)"
for ext in "${exts[@]}"; do
    list="${names[$ext]%, }"                      # strip the trailing ", "
    printf '%-7s %d  %s\n' "$ext" "${count[$ext]}" "$list"
done

cd / && rm -rf -- "$work"
