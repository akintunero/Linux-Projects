#!/usr/bin/env bash
# Day 19 medium: two helpers that need arguments, so they are functions, not aliases.
# Temporary files only.
set -euo pipefail

mkcd() {
    [[ $# -eq 1 ]] || { echo "usage: mkcd DIR" >&2; return 2; }
    mkdir -p -- "$1" && cd -- "$1"
}

extract() {
    [[ -f ${1:-} ]] || { echo "extract: '${1:-}' is not a file" >&2; return 1; }
    case "$1" in
        *.tar.gz|*.tgz) tar -xzf "$1" ;;
        *.tar)          tar -xf "$1" ;;
        *.zip)          unzip -q "$1" ;;
        *)              echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
    esac
}

work="$(mktemp -d)"
cd "$work"

mkcd "projects/my demo"
echo "mkcd: now in '${PWD##*/}'"
cd "$work"

mkdir -p src && echo "payload" > src/f.txt
tar -czf src.tgz src && tar -cf src.tar src
rm -r src

extract src.tgz && echo "tgz  -> $(cat src/f.txt)"
rm -r src
extract src.tar && echo "tar  -> $(cat src/f.txt)"

touch notes.rar
status=0
extract notes.rar || status=$?
echo "unknown type -> exit ${status}"
status=0
extract missing.tgz || status=$?
echo "missing file -> exit ${status}"

cd / && rm -rf -- "$work"
