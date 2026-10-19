#!/usr/bin/env bash
# Day 09 - Medium: which package owns the grep program on this machine?
# dpkg -S (Debian/Ubuntu) or rpm -qf (RHEL family). Read-only. The rpm branch was not run by the author.
set -euo pipefail

path=$(command -v grep)
path=$(readlink -f -- "$path")          # resolve symlinks such as /bin -> /usr/bin
if command -v dpkg >/dev/null; then
  owner=$(dpkg -S "$path" | cut -d: -f1)
elif command -v rpm >/dev/null; then
  owner=$(rpm -qf --qf '%{NAME}' "$path")
else
  echo "no supported package database found" >&2; exit 77
fi
echo "$path is owned by package: $owner"

[[ $owner == grep ]] || { echo "FAIL: expected grep, got $owner" >&2; exit 1; }
echo PASS >&2
