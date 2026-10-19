#!/usr/bin/env bash
# Day 09 easy: a backup target list as an array, with a numbered report.
set -euo pipefail

targets=("/etc" "/var/log" "/home/shared files")
targets+=("/srv/www")

echo "Backup targets (${#targets[@]}):"
for i in "${!targets[@]}"; do
    echo "$(( i + 1 )). ${targets[i]}"
done
echo "Last target: ${targets[-1]}"
