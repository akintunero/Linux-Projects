#!/usr/bin/env bash
# Day 13 - Easy: percentage of memory in use, computed from /proc/meminfo.
# "In use" means MemTotal minus MemAvailable (what a new program could NOT get without swapping).
# Read-only.
set -euo pipefail

mem_used_pct() {
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {printf "%d\n", (t - a) * 100 / t}' "${1:-/proc/meminfo}"
}

pct=$(mem_used_pct)
echo "memory used: ${pct}%"

# Acceptance checks
((pct >= 0 && pct <= 100)) || { echo "FAIL: out of range" >&2; exit 1; }
w=$(mktemp); trap 'rm -f "$w"' EXIT
printf 'MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 250 kB\n' > "$w"
[[ $(mem_used_pct "$w") == 75 ]] || { echo "FAIL: fixture should give 75" >&2; exit 1; }
echo PASS >&2
