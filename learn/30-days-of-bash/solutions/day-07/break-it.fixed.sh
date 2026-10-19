#!/usr/bin/env bash
# Fixed: pass arguments to main, check them, define die, and use [[ ]] with quotes.
# Run it as:  bash break-it.fixed.sh /tmp
set -euo pipefail

die() {
    echo "error: $*" >&2
    exit 1
}

main() {
    (( $# == 1 )) || die "usage: ${0##*/} DIRECTORY"
    local dest="$1"
    [[ -d $dest ]] || die "no such directory: $dest"
    echo "cleaning $dest"
}

main "${@:-/tmp}"
