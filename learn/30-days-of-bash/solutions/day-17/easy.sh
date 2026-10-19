#!/usr/bin/env bash
# Day 17 easy: clean up *.tmp files older than 7 days - dry run first, delete only on request.
# Temporary files only.
set -euo pipefail

cleanup() {
    local dir="$1" apply="$2"
    echo "candidates (older than 7 days):"
    find "$dir" -type f -name '*.tmp' -mtime +7 -printf '  %f\n' | sort
    if (( apply )); then
        find "$dir" -type f -name '*.tmp' -mtime +7 -delete
        echo "deleted."
    else
        echo "dry run: nothing deleted (call with apply=1 to delete)"
    fi
}

work="$(mktemp -d)"
touch -d '10 days ago' "${work}/old one.tmp" "${work}/old two.tmp"
touch "${work}/fresh.tmp" "${work}/keep.txt"

cleanup "$work" 0
echo "--- files still present: $(find "$work" -type f | wc -l)"
cleanup "$work" 1
echo "--- files still present: $(find "$work" -type f | wc -l)"

rm -rf -- "$work"
