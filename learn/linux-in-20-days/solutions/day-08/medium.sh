#!/usr/bin/env bash
# Day 08 - Medium: find the space hogs - subdirectories (including hidden ones) largest first.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p tree/a tree/b tree/.cache
dd if=/dev/zero of=tree/a/big bs=1M count=3 status=none
dd if=/dev/zero of=tree/b/small bs=1k count=10 status=none
dd if=/dev/zero of=tree/.cache/hidden bs=1M count=5 status=none

# find lists hidden directories too; `du *` would not. -k gives plain numbers that sort -n can handle.
out=$(du -k --max-depth=1 tree | sort -rn | awk '{print $2}')
echo "$out"

[[ $(sed -n 1p <<<"$out") == tree ]]              || { echo "FAIL: total first" >&2; exit 1; }
[[ $(sed -n 2p <<<"$out") == tree/.cache ]]       || { echo "FAIL: hidden hog not second" >&2; exit 1; }
[[ $(sed -n 3p <<<"$out") == tree/a ]]            || { echo "FAIL: a not third" >&2; exit 1; }
echo PASS >&2
