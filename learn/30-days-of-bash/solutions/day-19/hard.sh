#!/usr/bin/env bash
# Day 19 hard: a safer replacement for rm - move files to a trash folder instead of deleting.
# Everything happens inside a temporary directory, including the trash itself.
set -euo pipefail

work="$(mktemp -d)"
TRASH_DIR="${work}/trash"

trash() {
    local f base dest n rc=0
    mkdir -p -- "$TRASH_DIR"
    for f in "$@"; do
        if [[ ! -e $f ]]; then
            echo "trash: ${f}: no such file" >&2
            rc=1
            continue
        fi
        base="${f##*/}"
        dest="${TRASH_DIR}/${base}"
        n=1
        while [[ -e $dest ]]; do              # never overwrite an earlier trashed file
            dest="${TRASH_DIR}/${base}.${n}"
            n=$(( n + 1 ))
        done
        mv -- "$f" "$dest"
        echo "trashed: ${f} -> ${dest##*/}"
    done
    return "$rc"
}

trash_list() {
    echo "in trash:"
    ls -1 "$TRASH_DIR" | sed 's/^/  /'
}

trash_empty() {
    if [[ ${CONFIRM:-no} != yes ]]; then
        echo "trash_empty: set CONFIRM=yes to really delete $(ls -1 "$TRASH_DIR" | wc -l) item(s)" >&2
        return 1
    fi
    rm -rf -- "${TRASH_DIR:?}"/*
    echo "trash emptied"
}

cd "$work"
mkdir -p a b
echo one > a/report.txt
echo two > b/report.txt
echo three > "my notes.txt"

trash a/report.txt b/report.txt "my notes.txt"
status=0
trash does-not-exist.txt || status=$?
echo "exit status for a missing file: ${status}"

trash_list
status=0
trash_empty || status=$?
echo "without confirmation: exit ${status}, still $(ls -1 "$TRASH_DIR" | wc -l) item(s)"
CONFIRM=yes trash_empty
echo "left in trash: $(ls -1 "$TRASH_DIR" | wc -l)"

cd / && rm -rf -- "$work"
