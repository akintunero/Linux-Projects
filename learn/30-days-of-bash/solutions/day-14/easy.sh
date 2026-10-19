#!/usr/bin/env bash
# Day 14 easy: a debug() helper switched on by DEBUG=1.
# Try:  bash easy.sh      and      DEBUG=1 bash easy.sh
set -euo pipefail

debug() {
    if [[ ${DEBUG:-0} == 1 ]]; then
        echo "[debug] $*" >&2
    fi
    return 0
}

debug "starting up"
count=3
debug "count is ${count}"
echo "processed ${count} items"
