#!/usr/bin/env bash
# Day 13 - Break it, fixed. Bugs were:
#   1. `uptime | awk '{print $10}'` picks a column that moves (days, users, "min"), and keeps a trailing comma.
#      Read /proc/loadavg: its first field is always the 1-minute load.
#   2. `[ $load -gt $cpus ]` cannot compare decimals ("integer expression expected") -> compare in awk.
#   3. MemFree ignores reclaimable cache, so a healthy machine looks nearly full -> use MemAvailable.
# Overrides for testing: NPROC=n LOADAVG=file MEMINFO=file.  Self-test: break-it.fixed.sh --self-test
set -uo pipefail

report() {
  local cpus=${NPROC:-$(nproc)} loadavg=${LOADAVG:-/proc/loadavg} meminfo=${MEMINFO:-/proc/meminfo}
  if awk -v c="$cpus" '{exit !($1 > c)}' "$loadavg"; then echo OVERLOADED; else echo "load ok"; fi
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {printf "memory used: %d%%\n", (t - a) * 100 / t}' "$meminfo"
}

if [[ ${1:-} == --self-test ]]; then
  w=$(mktemp -d); trap 'rm -rf "$w"' EXIT
  printf '6.50 3.00 2.00 1/100 1\n' > "$w/high"; printf '0.50 3.00 2.00 1/100 1\n' > "$w/low"
  printf 'MemTotal: 1000 kB\nMemFree: 50 kB\nMemAvailable: 600 kB\n' > "$w/mem"
  out=$(NPROC=4 LOADAVG=$w/high MEMINFO=$w/mem report)
  [[ $out == $'OVERLOADED\nmemory used: 40%' ]] || { echo "FAIL high: $out" >&2; exit 1; }
  out=$(NPROC=4 LOADAVG=$w/low MEMINFO=$w/mem report)
  [[ $out == $'load ok\nmemory used: 40%' ]] || { echo "FAIL low: $out" >&2; exit 1; }
  echo PASS >&2
else
  report
fi
