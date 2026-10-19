#!/usr/bin/env bash
# Fixed: quote the value, use double quotes to expand, and use $(( )) for math.
set -euo pipefail

name="Ada Lovelace"
count=4
echo "$name has $count files"
total=$(( count + 1 ))
echo "next: $total"
