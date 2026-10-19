#!/usr/bin/env bash
# Day 05 hard: rotate every *.log bigger than max_bytes, keeping 3 old copies.
# Works only inside a temporary directory it creates; safe to run anywhere.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
max_bytes=1000
keep=3

# Sample data: one big log with history, one small log.
head -c 1500 /dev/zero | tr '\0' 'x' > app.log
echo "gen1" > app.log.1
echo "gen2" > app.log.2
echo "gen3" > app.log.3
echo "tiny" > small.log

for log in *.log; do
    size="$(stat -c %s -- "$log")"
    if (( size <= max_bytes )); then
        echo "skip   $log (${size} bytes)"
        continue
    fi
    rm -f -- "${log}.${keep}"                       # the oldest copy falls off the end
    for (( i = keep - 1; i >= 1; i-- )); do
        if [[ -e "${log}.${i}" ]]; then
            mv -- "${log}.${i}" "${log}.$(( i + 1 ))"
        fi
    done
    mv -- "$log" "${log}.1"
    : > "$log"                                      # fresh empty log
    echo "rotate $log (${size} bytes)"
done

echo "--- result"
stat -c '%n %s bytes' app.log* small.log

cd / && rm -rf -- "$work"
