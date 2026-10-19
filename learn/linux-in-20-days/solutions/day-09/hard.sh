#!/usr/bin/env bash
# Day 09 - Hard: pkginfo.sh NAME - is it installed, which version is available, and what would
# installing it do? Never installs anything; apt-get -s is a simulation that needs no root.
# Exit status: 0 installed, 1 not installed, 2 unknown package or usage error.
# The dnf branch is written from the documentation and was not run by the author.
# Usage: hard.sh NAME | hard.sh --self-test
set -euo pipefail

pkginfo() {
  local name=${1:?usage: pkginfo NAME}
  if command -v dpkg-query >/dev/null; then
    local candidate
    candidate=$(apt-cache policy "$name" 2>/dev/null | awk '/Candidate:/ {print $2}')
    if [[ -z $candidate || $candidate == "(none)" ]]; then
      echo "unknown package: $name" >&2; return 2
    fi
    echo "available: $candidate"
    if dpkg-query -W -f='${Status}' "$name" 2>/dev/null | grep -q '^install ok installed'; then
      echo "installed: $(dpkg-query -W -f='${Version}' "$name")"; return 0
    fi
    echo "installed: no"
    apt-get -s install "$name" 2>/dev/null | grep '^Inst ' | sed 's/^/would install: /' | head -n 5 || true
    return 1
  elif command -v dnf >/dev/null; then
    dnf -q info "$name" >/dev/null 2>&1 || { echo "unknown package: $name" >&2; return 2; }
    if rpm -q "$name" >/dev/null 2>&1; then echo "installed: $(rpm -q "$name")"; return 0; fi
    echo "installed: no"; return 1
  fi
  echo "no supported package manager" >&2; return 2
}

self_test() {
  command -v apt-cache >/dev/null || { echo "apt-cache not available" >&2; exit 77; }
  local out rc=0
  out=$(pkginfo bash) || rc=$?
  [[ $rc -eq 0 ]] && grep -q '^installed: ' <<<"$out" || { echo "FAIL: bash should be installed" >&2; return 1; }
  rc=0; pkginfo no-such-package-xyz >/dev/null 2>&1 || rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL: unknown package rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else pkginfo "$@"; fi
