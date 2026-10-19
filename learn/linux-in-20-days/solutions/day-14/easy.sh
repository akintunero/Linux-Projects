#!/usr/bin/env bash
# Day 14 - Easy: a timestamped tar.gz of a directory, its listing, and a SHA-256 checksum file.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p site/css
echo "<h1>home</h1>" > site/index.html
echo "body{}" > site/css/main.css

archive="site-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$archive" site                       # relative paths: restores anywhere
tar -tzf "$archive"                            # list without extracting
sha256sum "$archive" > "$archive.sha256"
sha256sum -c "$archive.sha256"

# Acceptance checks
[[ -s $archive && -s $archive.sha256 ]]              || { echo "FAIL: missing files" >&2; exit 1; }
tar -tzf "$archive" | grep -qx 'site/css/main.css'   || { echo "FAIL: content missing" >&2; exit 1; }
! tar -tzf "$archive" | grep -q '^/'                 || { echo "FAIL: absolute path stored" >&2; exit 1; }
echo PASS >&2
