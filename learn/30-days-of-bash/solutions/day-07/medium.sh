#!/usr/bin/env bash
# Day 07 medium: backup that refuses to overwrite and verifies the archive.
# Works on temporary data only.
set -euo pipefail

err() { echo "error: $*" >&2; }

backup_dir() {
    local src="$1" dest="$2" stamp="$3" archive
    archive="${dest}/$(basename -- "$src")-${stamp}.tar.gz"
    mkdir -p -- "$dest"
    if [[ -e $archive ]]; then
        err "$(basename -- "$archive") already exists"
        return 3
    fi
    tar -czf "$archive" -C "$(dirname -- "$src")" -- "$(basename -- "$src")"
    if ! tar -tzf "$archive" >/dev/null; then
        err "archive failed verification"
        return 4
    fi
    echo "created and verified $(basename -- "$archive")"
}

main() {
    local work status=0
    work="$(mktemp -d)"
    mkdir -p "$work/site"
    echo "hello" > "$work/site/index.html"

    backup_dir "$work/site" "$work/out" "20250101-120000"
    backup_dir "$work/site" "$work/out" "20250101-120000" || status=$?
    echo "second run exit status: ${status}"

    rm -rf -- "$work"
}

main "$@"
