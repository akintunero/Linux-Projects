#!/usr/bin/env bash
# Fixed: define the variable before the trap, single-quote the trap so it expands at exit
# time, and tolerate grep's "no match" status on purpose.
export TMPDIR="$PWD/tmp"
mkdir -p "$TMPDIR"

(
    set -e
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' EXIT
    echo "data" > "$work/file"
    matches="$(grep -c needle "$work/file" || true)"
    echo "matches: $matches"
)
echo "subshell exit status: $?"
echo "leftover temp dirs: $(ls "$TMPDIR" | wc -l)"
