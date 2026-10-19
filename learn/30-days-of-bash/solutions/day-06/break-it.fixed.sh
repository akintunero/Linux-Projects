#!/usr/bin/env bash
# Fixed: locals do not leak, and the result travels through stdout, not through return.
# (return carries only a status 0-255, and a non-zero status aborts the script under set -e.)
set -euo pipefail

total=100

sum_to() {
    local sum=0 i
    for (( i = 1; i <= $1; i++ )); do
        sum=$(( sum + i ))
    done
    echo "$sum"
}

echo "starting with total=$total"
result="$(sum_to 3)"
echo "sum of 1..3 is $result"
echo "total is still $total"
echo "done"
