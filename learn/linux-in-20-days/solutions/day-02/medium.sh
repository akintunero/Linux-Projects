#!/usr/bin/env bash
# Day 02 - Medium: copy proj to proj.bak, rename README.md there, remove empty tests/ in the original.
# Safe: works inside a temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p proj/{src,docs,tests}
touch proj/src/app.sh proj/docs/README.md

cp -a proj proj.bak                       # -a keeps timestamps and permissions
mv proj.bak/docs/README.md proj.bak/docs/README.txt
rmdir proj/tests                          # rmdir refuses non-empty directories: a safety net

# Acceptance checks
[[ ! -e proj/tests ]]                 || { echo "FAIL: proj/tests still exists" >&2; exit 1; }
[[ -d proj.bak/tests ]]               || { echo "FAIL: backup lost tests/" >&2; exit 1; }
[[ -f proj/docs/README.md ]]          || { echo "FAIL: original README changed" >&2; exit 1; }
[[ -f proj.bak/docs/README.txt ]]     || { echo "FAIL: copy not renamed" >&2; exit 1; }
echo PASS >&2
