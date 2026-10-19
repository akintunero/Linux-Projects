#!/usr/bin/env bash
# Fixed: "n:" so -n takes a value, shift away the options, and quote "$@".
set -euo pipefail

set -- -v -n 3 report.txt "my notes.txt"      # pretend these came from the command line

verbose=0
lines=10
while getopts "vn:" opt; do
    case $opt in
        v) verbose=1 ;;
        n) lines=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

echo "verbose=$verbose lines=$lines"
for f in "$@"; do
    echo "file: $f"
done
