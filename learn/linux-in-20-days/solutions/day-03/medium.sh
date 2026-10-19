#!/usr/bin/env bash
# Day 03 - Medium: a "current" symlink that is switched from release v1 to v2.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p releases/v1 releases/v2
echo one > releases/v1/version.txt
echo two > releases/v2/version.txt

ln -sfn releases/v1 current
[[ $(cat current/version.txt) == one ]] || { echo "FAIL: v1" >&2; exit 1; }

# -n treats an existing symlink-to-directory as a file (replace it, do not descend into it);
# -f replaces the existing link. Without -n you would create releases/v1/v2.
ln -sfn releases/v2 current

readlink current
[[ $(readlink current) == releases/v2 ]] || { echo "FAIL: link target" >&2; exit 1; }
[[ $(cat current/version.txt) == two ]]  || { echo "FAIL: v2" >&2; exit 1; }
[[ ! -e releases/v1/v2 ]]                || { echo "FAIL: nested link created" >&2; exit 1; }
echo PASS >&2
