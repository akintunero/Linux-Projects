#!/usr/bin/env bash
# Day 03 - Hard: linkcheck.sh DIR - report dangling symlinks and hard-linked files.
# Usage: hard.sh DIR | hard.sh --self-test
# Safe: read-only on DIR; the self-test uses a temporary directory.
set -euo pipefail

linkcheck() {
  local dir=${1:?usage: linkcheck DIR}
  [[ -d $dir ]] || { echo "not a directory: $dir" >&2; return 2; }
  local p
  # -xtype l matches symlinks whose target does not exist (GNU find).
  while IFS= read -r -d '' p; do echo "dangling: $p"; done \
    < <(find "$dir" -xtype l -print0 | sort -z)
  # Regular files with more than one hard link share an inode.
  while IFS= read -r -d '' p; do echo "hardlinked: $p"; done \
    < <(find "$dir" -type f -links +1 -print0 | sort -z)
}

self_test() {
  local work out; work=$(mktemp -d); trap 'rm -rf "$work"' RETURN
  mkdir "$work/d"; echo x > "$work/d/real"; ln "$work/d/real" "$work/d/hard"
  ln -s "$work/d/real" "$work/d/ok"; ln -s nowhere "$work/d/broken"
  out=$(linkcheck "$work/d")
  grep -q "^dangling: .*/broken$" <<<"$out"   || { echo "FAIL: broken not reported" >&2; return 1; }
  grep -q "/ok$" <<<"$out" && grep -q "dangling: .*/ok" <<<"$out" && { echo "FAIL: ok reported" >&2; return 1; }
  [[ $(grep -c '^hardlinked:' <<<"$out") -eq 2 ]] || { echo "FAIL: expected 2 hardlinked" >&2; return 1; }
  (linkcheck "$work/nope" 2>/dev/null) && { echo "FAIL: bad dir accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else linkcheck "$@"; fi
