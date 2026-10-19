#!/usr/bin/env bash
# Day 09 - Break it (BUGGY on purpose). Debian/Ubuntu only. Read-only.
# Goal: report whether the package named in $1 is installed and, if so, its version.
pkg=${1:-bash}

if dpkg -l | grep $pkg; then
  version=$(dpkg -s $pkg | grep '^Version' | cut -d' ' -f1)
  echo "$pkg is installed, version $version"
else
  echo "$pkg is not installed"
fi
