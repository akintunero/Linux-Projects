#!/usr/bin/env bash
# Day 13 - Hard: snapshot.sh [WARN [CRIT]] - one-line resource snapshot with monitoring-style exit codes.
#   Output: STATE load_pct=.. mem_pct=.. disk_pct=..     STATE is OK / WARNING / CRITICAL
#   Exit:   0 OK, 1 WARNING (worst metric >= WARN, default 80), 2 CRITICAL (>= CRIT, default 95)
# load_pct = 1-minute load average as a percentage of the CPU count.
# Test overrides: LOADAVG=file MEMINFO=file NPROC=n DISK_PCT=n
# Usage: hard.sh [80 [95]] | hard.sh --self-test        Read-only.
set -uo pipefail

snapshot() {
  local warn=${1:-80} crit=${2:-95}
  local loadavg=${LOADAVG:-/proc/loadavg} meminfo=${MEMINFO:-/proc/meminfo}
  local cpus=${NPROC:-$(nproc)} disk=${DISK_PCT:-}
  [[ $warn =~ ^[0-9]+$ && $crit =~ ^[0-9]+$ ]] && ((warn < crit)) || { echo "usage: snapshot [WARN [CRIT]] (WARN < CRIT)" >&2; return 64; }
  [[ -n $disk ]] || disk=$(df -P / | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')

  local load_pct mem_pct worst state rc
  load_pct=$(awk -v c="$cpus" '{printf "%d\n", $1 * 100 / c}' "$loadavg")
  mem_pct=$(awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {printf "%d\n", (t - a) * 100 / t}' "$meminfo")
  worst=$load_pct
  ((mem_pct > worst)) && worst=$mem_pct
  ((disk > worst)) && worst=$disk

  if ((worst >= crit)); then state=CRITICAL rc=2
  elif ((worst >= warn)); then state=WARNING rc=1
  else state=OK rc=0; fi
  echo "$state load_pct=$load_pct mem_pct=$mem_pct disk_pct=$disk"
  return "$rc"
}

self_test() {
  local w out rc; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  printf '1.00 0.50 0.25 1/100 1234\n' > "$w/load_low";  printf '3.40 4.00 2.00 1/100 1234\n' > "$w/load_high"
  printf 'MemTotal: 1000 kB\nMemAvailable: 900 kB\n' > "$w/mem_ok"
  printf 'MemTotal: 1000 kB\nMemAvailable: 40 kB\n'  > "$w/mem_crit"
  export NPROC=4

  out=$(LOADAVG=$w/load_low MEMINFO=$w/mem_ok DISK_PCT=10 snapshot); rc=$?
  [[ $rc -eq 0 && $out == "OK load_pct=25 mem_pct=10 disk_pct=10" ]] || { echo "FAIL ok: $rc $out" >&2; return 1; }
  out=$(LOADAVG=$w/load_high MEMINFO=$w/mem_ok DISK_PCT=10 snapshot); rc=$?
  [[ $rc -eq 1 && $out == WARNING* ]] || { echo "FAIL warn: $rc $out" >&2; return 1; }   # 85% load
  out=$(LOADAVG=$w/load_low MEMINFO=$w/mem_crit DISK_PCT=10 snapshot); rc=$?
  [[ $rc -eq 2 && $out == CRITICAL* ]] || { echo "FAIL crit: $rc $out" >&2; return 1; }  # 96% memory
  out=$(LOADAVG=$w/load_low MEMINFO=$w/mem_ok DISK_PCT=85 snapshot 90 99); rc=$?
  [[ $rc -eq 0 ]] || { echo "FAIL custom thresholds: $rc" >&2; return 1; }
  snapshot 95 80 >/dev/null 2>&1; rc=$?
  [[ $rc -eq 64 ]] || { echo "FAIL bad thresholds rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else snapshot "$@"; fi
