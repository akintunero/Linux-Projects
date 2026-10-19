#!/usr/bin/env bash
# Day 06 medium: file_size_mb prints a value; require_file returns a status.
set -euo pipefail

file_size_mb() {
    local bytes
    bytes="$(stat -c %s -- "$1")"
    echo $(( bytes / 1024 / 1024 ))
}

require_file() {
    if [[ ! -f $1 ]]; then
        echo "error: $1 is not a file" >&2
        return 1
    fi
}

work="$(mktemp -d)"
head -c 3145728 /dev/zero > "$work/big.bin"          # 3 MiB

require_file "$work/big.bin"
size="$(file_size_mb "$work/big.bin")"
echo "big.bin is ${size} MB"

if ! require_file "$work/missing.bin"; then
    echo "missing.bin check failed as expected"
fi

rm -rf -- "$work"
