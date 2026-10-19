#!/usr/bin/env bash
# Day 13 medium: audit a tree for world-writable files and fix them.
# Works on a temporary tree only.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
mkdir -p site/uploads
touch site/index.html site/uploads/a.txt "site/uploads/my file.txt"
chmod 666 site/uploads/a.txt "site/uploads/my file.txt"

echo "Before:"
find site -type f -perm -o+w -print0 | sort -z | while IFS= read -r -d '' f; do
    echo "  world-writable: $f"
done

# -exec ... {} + passes many files to one chmod and handles odd names safely.
find site -type f -perm -o+w -exec chmod o-w {} +

echo "After: $(find site -type f -perm -o+w | wc -l) world-writable file(s)"
stat -c '%a %n' site/uploads/a.txt "site/uploads/my file.txt"

cd / && rm -rf -- "$work"
