#!/usr/bin/env bash
# Day 01 - Easy: print "Distro: <PRETTY_NAME>" from /etc/os-release.
# Safe: read-only.
set -euo pipefail

# shellcheck disable=SC1091
. /etc/os-release
line="Distro: ${PRETTY_NAME}"
echo "$line"

# Acceptance check
[[ "$line" == "Distro: "?* ]] || { echo "FAIL: empty distro name" >&2; exit 1; }
echo "PASS" >&2
