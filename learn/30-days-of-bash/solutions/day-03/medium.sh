#!/usr/bin/env bash
# Day 03 medium: format a disk report from raw kilobyte numbers.
set -euo pipefail

used_kb=45678
total_kb=102400

used_mb=$(( used_kb / 1024 ))
total_mb=$(( total_kb / 1024 ))
percent=$(( used_kb * 100 / total_kb ))   # multiply first, or integer division gives 0
free_mb=$(( total_mb - used_mb ))

echo "Used: ${used_mb} MB of ${total_mb} MB (${percent}%)"
echo "Free: ${free_mb} MB"
