#!/usr/bin/env bash
# Fixed: NUL-separated names for xargs, and a process substitution so the loop runs
# in the current shell and the counter survives.
set -euo pipefail

touch "a b.tmp" c.tmp d.txt

find . -name '*.tmp' -print0 | xargs -0 rm --
ls

count=0
while IFS= read -r -d '' _; do
    count=$(( count + 1 ))
done < <(find . -name '*.txt' -print0)
echo "text files: $count"
