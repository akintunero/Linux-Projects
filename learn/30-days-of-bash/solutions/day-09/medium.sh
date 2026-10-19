#!/usr/bin/env bash
# Day 09 medium: count HTTP status codes with an associative array.
set -euo pipefail

statuses=(200 200 404 500 200 404 301 503)
declare -A hits

for code in "${statuses[@]}"; do
    hits[$code]=$(( ${hits[$code]:-0} + 1 ))
done

mapfile -t codes <<< "$(printf '%s\n' "${!hits[@]}" | sort -n)"

server_errors=0
for code in "${codes[@]}"; do
    printf '%s: %s\n' "$code" "${hits[$code]}"
    if [[ $code == 5?? ]]; then
        server_errors=$(( server_errors + hits[$code] ))
    fi
done
echo "server errors (5xx): ${server_errors}"
