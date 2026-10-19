#!/usr/bin/env bash
# Day 07 hard: backup with retention. Keep only the newest N archives.
# Works on temporary data only.
set -euo pipefail
shopt -s nullglob

prune() {
    local dest="$1" name="$2" keep="$3"
    local archives=("${dest}/${name}"-*.tar.gz)   # glob results are sorted; timestamps sort too
    local total="${#archives[@]}" i
    for (( i = 0; i < total - keep; i++ )); do
        echo "pruning $(basename -- "${archives[i]}")"
        rm -- "${archives[i]}"
    done
}

main() {
    local work stamp
    work="$(mktemp -d)"
    mkdir -p "$work/site" "$work/out"
    echo "data" > "$work/site/file.txt"

    for stamp in 20250101 20250102 20250103 20250104 20250105; do
        tar -czf "$work/out/site-${stamp}.tar.gz" -C "$work" site
    done

    prune "$work/out" site 3

    echo "remaining:"
    for f in "$work"/out/*.tar.gz; do
        basename -- "$f"
    done

    rm -rf -- "$work"
}

main "$@"
