#!/usr/bin/env bash
# Day 05 - Easy: the file you would create by typing three lines in nano and saving (^O Enter, ^X).
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

# Interactive version:  nano notes.txt   -> type 3 lines -> Ctrl+O, Enter, Ctrl+X
printf 'buy milk\ncall Sam\nread man page for tar\n' > notes.txt
cat notes.txt

[[ $(wc -l < notes.txt) -eq 3 ]]              || { echo "FAIL: need 3 lines" >&2; exit 1; }
grep -qx 'call Sam' notes.txt                  || { echo "FAIL: missing line" >&2; exit 1; }
echo PASS >&2
