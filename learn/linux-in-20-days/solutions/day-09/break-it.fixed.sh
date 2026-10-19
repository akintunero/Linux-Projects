#!/usr/bin/env bash
# Day 09 - Break it, fixed. Debian/Ubuntu only. Read-only. Bugs were:
#   1. `dpkg -l | grep bash` matches every package with "bash" in its line (bash-completion ...)
#      and prints that noise. Ask for the exact package with dpkg-query.
#   2. `cut -d' ' -f1` returns the word "Version:"; the number is field 2 (or use -W -f).
#   3. Unquoted $pkg, and dpkg -s prints errors for packages that are not installed.
# Safe: read-only. Self-test: break-it.fixed.sh --self-test
set -euo pipefail

report() {
  local pkg=$1 status
  status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
  if [[ $status == "install ok installed" ]]; then
    echo "$pkg is installed, version $(dpkg-query -W -f='${Version}' "$pkg")"
  else
    echo "$pkg is not installed"
  fi
}

if [[ ${1:-} == --self-test ]]; then
  command -v dpkg-query >/dev/null || { echo "dpkg not available" >&2; exit 77; }
  [[ $(report bash) == "bash is installed, version "?* ]] || { echo "FAIL: bash" >&2; exit 1; }
  [[ $(report no-such-package-xyz) == "no-such-package-xyz is not installed" ]] || { echo "FAIL: absent" >&2; exit 1; }
  [[ $(report bash-complet) == "bash-complet is not installed" ]] || { echo "FAIL: partial name matched" >&2; exit 1; }
  echo PASS >&2
else
  report "${1:-bash}"
fi
