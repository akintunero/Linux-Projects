#!/usr/bin/env bash
# Day 15 easy: a die() helper and meaningful exit codes.
# Runs the checks in subshells so this demo itself can report each exit status.
set -euo pipefail

die() {
    local code="$1"
    shift
    echo "error: $*" >&2
    exit "$code"
}

require_file() {
    [[ -f $1 ]] || die 66 "required file '$1' not found"
}

status=0
( require_file /etc/os-release ) || status=$?
echo "existing file: exit status ${status}"

status=0
( require_file /no/such/config.ini ) || status=$?
echo "missing file:  exit status ${status}"
