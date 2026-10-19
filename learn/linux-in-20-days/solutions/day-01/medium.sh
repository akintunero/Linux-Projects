#!/usr/bin/env bash
# Day 01 - Medium: classify cd, ls, if, grep with `type -t` and write tools.txt.
# Safe: writes only inside a temporary directory.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

for name in cd ls if grep; do
  # `type -t` prints alias, keyword, function, builtin or file.
  # In a non-interactive script no aliases are defined, so ls is "file".
  printf '%s: %s\n' "$name" "$(type -t "$name")"
done > tools.txt

cat tools.txt

# Acceptance checks
[[ $(wc -l < tools.txt) -eq 4 ]]          || { echo "FAIL: need 4 lines" >&2; exit 1; }
grep -qx 'cd: builtin' tools.txt          || { echo "FAIL: cd" >&2; exit 1; }
grep -qx 'if: keyword' tools.txt          || { echo "FAIL: if" >&2; exit 1; }
grep -qx 'ls: file' tools.txt             || { echo "FAIL: ls" >&2; exit 1; }
echo "PASS" >&2
