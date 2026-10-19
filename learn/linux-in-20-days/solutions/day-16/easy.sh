#!/usr/bin/env bash
# Day 16 - Easy: let systemd explain calendar expressions BEFORE you put them in a timer.
# Prints the normalised form of three schedules and checks them. Read-only, no root.
# NEEDS-TOOL: systemd-analyze (exits 77 if missing).
set -euo pipefail
command -v systemd-analyze >/dev/null || { echo "systemd-analyze missing" >&2; exit 77; }

normalized() { systemd-analyze calendar "$1" | sed -n 's/^ *Normalized form: //p'; }

weekdays=$(normalized 'Mon..Fri 02:30')
quarter=$(normalized '*:0/15')
daily=$(normalized 'daily')
printf '%s\n%s\n%s\n' "$weekdays" "$quarter" "$daily"

[[ $weekdays == 'Mon..Fri *-*-* 02:30:00' ]] || { echo "FAIL: weekdays" >&2; exit 1; }
[[ $quarter  == '*-*-* *:00/15:00' ]]        || { echo "FAIL: quarter" >&2; exit 1; }
[[ $daily    == '*-*-* 00:00:00' ]]          || { echo "FAIL: daily" >&2; exit 1; }
systemd-analyze calendar 'nonsense' >/dev/null 2>&1 && { echo "FAIL: nonsense accepted" >&2; exit 1; }
echo PASS >&2
