#!/usr/bin/env bash
# Day 04 hard: disk-alert check with monitoring-style exit codes.
# 0 = OK, 1 = WARNING, 2 = CRITICAL. Read-only: it only runs df.
# Override for testing:  DISK_USAGE=95 bash hard.sh
set -euo pipefail

warn=80
crit=90
usage="${DISK_USAGE:-$(df --output=pcent / | tail -n 1 | tr -dc '0-9')}"

case "$usage" in
    ''|*[!0-9]*)                      # empty, or contains a non-digit
        echo "UNKNOWN: could not read disk usage" >&2
        exit 3
        ;;
esac

if (( usage >= crit )); then
    echo "CRITICAL: / is ${usage}% full (limit ${crit}%)"
    exit 2
elif (( usage >= warn )); then
    echo "WARNING: / is ${usage}% full (limit ${warn}%)"
    exit 1
fi
echo "OK: / is ${usage}% full"
