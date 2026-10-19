#!/usr/bin/env bash
# Day 08 easy: split stdout and stderr of one command into two files.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
touch one.txt two.txt

ls . missing-dir > out.txt 2> err.txt || true

echo "stdout lines: $(wc -l < out.txt)"
echo "stderr lines: $(wc -l < err.txt)"
echo "--- err.txt"
cat err.txt

cd / && rm -rf -- "$work"
