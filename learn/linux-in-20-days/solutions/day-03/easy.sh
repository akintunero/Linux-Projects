#!/usr/bin/env bash
# Day 03 - Easy: walk a tree using only relative paths.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p a/b/c
cd a/b/c
cd ../..                      # two levels up from c is a
name=$(basename "$PWD")
echo "now in: $name"

[[ $name == a ]] || { echo "FAIL: expected to be in a, got $name" >&2; exit 1; }
echo PASS >&2
