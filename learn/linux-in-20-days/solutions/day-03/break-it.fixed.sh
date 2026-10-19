#!/usr/bin/env bash
# Day 03 - Break it, fixed. Bugs were:
#   1. A relative symlink target is resolved relative to the directory that contains the link,
#      so links/current -> releases/v1 points at links/releases/v1 (does not exist).
#      Fix: use ../releases/v1, or an absolute path.
#   2. The second `ln -s` fails because links/current already exists -> add -f.
#   3. Even with -f, if current points at a directory, ln descends into it -> add -n.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p releases/v1 releases/v2 links
echo one > releases/v1/version.txt
echo two > releases/v2/version.txt

ln -sfn ../releases/v1 links/current
ln -sfn ../releases/v2 links/current
out=$(cat links/current/version.txt)
echo "$out"
[[ $out == two ]] || { echo "FAIL" >&2; exit 1; }
echo PASS >&2
