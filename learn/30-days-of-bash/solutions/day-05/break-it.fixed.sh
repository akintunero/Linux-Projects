#!/usr/bin/env bash
# Fixed: loop over the glob (not over `ls` output) and count inside the loop,
# not in a pipeline subshell.
set -euo pipefail
shopt -s nullglob

touch "my notes.txt" todo.txt

count=0
for f in *.txt; do
    echo "Processing $f"
    count=$(( count + 1 ))
done
echo "Total: $count"
