#!/usr/bin/env bash
# Day 09 - Easy: print the installed version of bash from the package database.
# Works on Debian/Ubuntu (dpkg-query) and RHEL family (rpm). Read-only, no root needed.
# The rpm branch is written from the documentation and was not run by the author.
set -euo pipefail

pkg=bash
if command -v dpkg-query >/dev/null; then
  version=$(dpkg-query -W -f='${Version}' "$pkg")
elif command -v rpm >/dev/null; then
  version=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$pkg")
else
  echo "no supported package database found" >&2; exit 77
fi
echo "$pkg $version"

[[ -n $version ]] || { echo "FAIL: empty version" >&2; exit 1; }
echo PASS >&2
