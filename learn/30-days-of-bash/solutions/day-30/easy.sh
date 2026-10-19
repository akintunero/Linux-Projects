#!/usr/bin/env bash
# Day 30 easy: fixture-based mini dashboard
# Reads uptime, meminfo, and loadavg fixtures and formats them.
set -euo pipefail

fx="$(mktemp -d)"
trap 'rm -rf -- "$fx"' EXIT

cat > "${fx}/uptime" <<'DATA'
93784.12 360000.00
DATA

cat > "${fx}/meminfo" <<'DATA'
MemTotal: 8000000 kB
MemAvailable: 1200000 kB
DATA

cat > "${fx}/loadavg" <<'DATA'
3.50 2.10 1.00 2/300 12345
DATA

# Format uptime as "1d 2h 3m"
secs="$(cut -d. -f1 "${fx}/uptime")"
days=$(( secs / 86400 ))
hours=$(( secs % 86400 / 3600 ))
mins=$(( secs % 3600 / 60 ))
uptime_fmt="${days}d ${hours}h ${mins}m"

# Memory used percent
mem_used="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d%%", (t - a) * 100 / t }' "${fx}/meminfo")"

# Load averages (1m, 5m, 15m)
read -r load1 load5 load15 _ < "${fx}/loadavg"

printf "UPTIME: %s\n" "$uptime_fmt"
printf "MEMORY: %s used\n" "$mem_used"
printf "LOAD:   %s (1m), %s (5m), %s (15m)\n" "$load1" "$load5" "$load15"
