#!/usr/bin/env bash
# Day 02 - Easy: build proj/{src,docs,tests} with two files.
# Safe: works inside a temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p proj/{src,docs,tests}
touch proj/src/app.sh proj/docs/README.md

find proj | sort

# Acceptance check
expected=$'proj\nproj/docs\nproj/docs/README.md\nproj/src\nproj/src/app.sh\nproj/tests'
[[ $(find proj | sort) == "$expected" ]] || { echo "FAIL: tree differs" >&2; exit 1; }
echo PASS >&2
