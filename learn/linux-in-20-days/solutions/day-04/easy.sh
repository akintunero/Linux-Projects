#!/usr/bin/env bash
# Day 04 - Easy: create report.txt with mode exactly 640.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

echo "Q3 numbers" > report.txt
chmod 640 report.txt
stat -c '%A %a %n' report.txt

[[ $(stat -c %a report.txt) == 640 ]] || { echo "FAIL" >&2; exit 1; }
echo PASS >&2
