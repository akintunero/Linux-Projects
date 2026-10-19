#!/usr/bin/env bash
# Day 14 medium: the classic "last line has no newline" bug, found and fixed.
set -euo pipefail

work="$(mktemp -d)"
printf '10\n20\n30' > "$work/numbers.txt"      # note: no newline after 30

echo "--- buggy loop"
sum=0
while IFS= read -r line; do
    sum=$(( sum + line ))
done < "$work/numbers.txt"
echo "sum = ${sum} (expected 60)"

echo "--- fixed loop: read returns non-zero on the final unterminated line, but still fills 'line'"
sum=0
while IFS= read -r line || [[ -n $line ]]; do
    sum=$(( sum + line ))
done < "$work/numbers.txt"
echo "sum = ${sum}"

echo "--- tracing the read with set -x and a line-number prefix"
PS4='+ line ${LINENO}: '
set -x
line=""
IFS= read -r line < "$work/numbers.txt"
set +x

rm -rf -- "$work"
