#!/usr/bin/env bash
# Day 16 medium: a mini disk-usage reporter with getopts: du-report.sh [-d DEPTH] [-h] DIR
# Demo data is created in a temporary directory; the parser is exercised with fixed arguments.
set -euo pipefail

parse_and_report() {
    local depth=1 opt OPTIND=1       # reset OPTIND so the function can be called repeatedly
    while getopts ":d:h" opt; do
        case "$opt" in
            d) depth="$OPTARG" ;;
            h) echo "usage: du-report [-d DEPTH] DIR"; return 0 ;;
            :) echo "error: -$OPTARG needs a value" >&2; return 2 ;;
            \?) echo "error: unknown option -$OPTARG" >&2; return 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    [[ $# -eq 1 ]] || { echo "error: exactly one directory required" >&2; return 2; }
    [[ -d $1 ]] || { echo "error: '$1' is not a directory" >&2; return 1; }
    case "$depth" in ''|*[!0-9]*) echo "error: depth must be a number" >&2; return 2 ;; esac

    echo "usage of $(basename -- "$1") to depth ${depth}:"
    du -b --max-depth="$depth" -- "$1" | sort -k2 | sed "s#${1}#.#"
}

work="$(mktemp -d)"
mkdir -p "${work}/app/logs" "${work}/app/cache"
head -c 2048 /dev/zero > "${work}/app/logs/a.log"
head -c 1024 /dev/zero > "${work}/app/cache/c.bin"

parse_and_report -d 1 "${work}/app"
status=0
parse_and_report -d two "${work}/app" || status=$?
echo "bad depth -> exit ${status}"
status=0
parse_and_report -q "${work}/app" || status=$?
echo "bad option -> exit ${status}"

rm -rf -- "$work"
