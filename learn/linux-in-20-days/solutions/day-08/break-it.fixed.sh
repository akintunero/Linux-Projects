#!/usr/bin/env bash
# Day 08 - Break it, fixed. Bugs were:
#   1. `du -sh *` does not match hidden entries such as .cache -> use `du -sh .[!.]* *` or du --max-depth=1.
#   2. `sort -n` cannot order human sizes (10K, 3.0M) -> use `sort -h`, or du -k with sort -n.
#   3. `df` prints "42%", so `[ $usage -gt 1 ]` fails with "integer expression expected" -> strip the %.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p tree/a tree/.cache
dd if=/dev/zero of=tree/a/big bs=1M count=3 status=none
dd if=/dev/zero of=tree/.cache/hidden bs=1M count=5 status=none

cd tree
out=$(du -h --max-depth=1 . | sort -rh)
echo "$out"

usage=$(df --output=pcent . | tail -n 1 | tr -dc '0-9')
echo "usage=${usage}%"
if ((usage >= 0)); then echo "numeric comparison works"; fi

second=$(sed -n 2p <<<"$out" | awk '{print $2}')
[[ $second == ./.cache ]] || { echo "FAIL: hidden dir not found second (got $second)" >&2; exit 1; }
echo PASS >&2
