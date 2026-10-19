#!/usr/bin/env bash
# Day 28 easy: memory report with a severity level, tested on a fixture file.
# Read-only. Pass a file to use it instead of /proc/meminfo.
set -euo pipefail

mem_report() {
    local file="${1:-/proc/meminfo}" warn=80 crit=90 total avail used pct level
    total="$(awk '/^MemTotal:/ { print $2 }' "$file")"
    avail="$(awk '/^MemAvailable:/ { print $2 }' "$file")"
    used=$(( total - avail ))
    pct=$(( used * 100 / total ))
    if (( pct >= crit )); then level=CRIT
    elif (( pct >= warn )); then level=WARN
    else level=OK
    fi
    printf 'memory: %d MB used of %d MB (%d%%) %s\n' $(( used / 1024 )) $(( total / 1024 )) "$pct" "$level"
    case "$level" in OK) return 0 ;; WARN) return 1 ;; *) return 2 ;; esac
}

work="$(mktemp -d)"
for pair in "8000000 6400000" "8000000 400000" "8000000 1200000"; do
    read -r total avail <<< "$pair"
    printf 'MemTotal: %d kB\nMemAvailable: %d kB\n' "$total" "$avail" > "${work}/meminfo"
    status=0
    mem_report "${work}/meminfo" || status=$?
    echo "  exit status ${status}"
done
rm -rf -- "$work"
