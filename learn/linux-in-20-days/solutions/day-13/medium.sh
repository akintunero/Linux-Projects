#!/usr/bin/env bash
# Day 13 - Medium: topcpu.sh [N] - the N busiest processes by CPU as "PID %CPU COMMAND".
# Usage: medium.sh 5   | medium.sh --self-test
# Read-only (the self-test starts and stops one CPU-burning `yes`).
set -uo pipefail

topcpu() {
  local n=${1:-5}
  [[ $n =~ ^[1-9][0-9]*$ ]] || { echo "N must be a positive integer" >&2; return 2; }
  # --sort=-pcpu: largest first. The trailing = on each column removes the header line.
  ps -eo pid=,pcpu=,comm= --sort=-pcpu | head -n "$n"
}

self_test() {
  local pid out
  yes > /dev/null & pid=$!
  trap 'kill "$pid" 2>/dev/null' RETURN
  sleep 2                                   # ps %CPU is an average since the process started
  out=$(topcpu 3)
  [[ $(wc -l <<<"$out") -eq 3 ]]                       || { echo "FAIL: need 3 lines" >&2; return 1; }
  awk -v p="$pid" '$1 == p {found = 1} END {exit !found}' <<<"$out" \
                                                       || { echo "FAIL: hog not in top 3" >&2; return 1; }
  topcpu 0 2>/dev/null && { echo "FAIL: 0 accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else topcpu "$@"; fi
