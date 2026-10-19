#!/usr/bin/env bash
# Day 02 - Hard: trash.sh - move files to a trash directory instead of deleting them.
# Usage: hard.sh FILE...          (TRASH_DIR overrides ~/.local/share/mytrash)
#        hard.sh --self-test
# Safe: only moves files; the self-test runs in a temporary directory.
set -euo pipefail

trash() {
  local dir=${TRASH_DIR:-$HOME/.local/share/mytrash}
  (($# > 0)) || { echo "usage: trash FILE..." >&2; return 2; }
  mkdir -p "$dir"
  local f target stamp n
  stamp=$(date +%Y%m%dT%H%M%S)
  for f in "$@"; do
    if [[ $(realpath -- "$f" 2>/dev/null) == / ]]; then
      echo "refusing to trash /" >&2; return 1
    fi
    [[ -e $f || -L $f ]] || { echo "no such file: $f" >&2; return 1; }
    target="$dir/$(basename -- "$f").$stamp"
    n=0
    while [[ -e $target ]]; do        # same name trashed twice in one second: add a counter
      n=$((n + 1)); target="$dir/$(basename -- "$f").$stamp.$n"
    done
    mv -n -- "$f" "$target"
    echo "trashed: $f -> $target"
  done
}

self_test() {
  local work; work=$(mktemp -d); trap 'rm -rf "$work"' RETURN
  cd "$work"
  export TRASH_DIR="$work/bin"
  mkdir sub
  echo one > "my file.txt"
  echo two > sub/note.txt
  trash "my file.txt" >/dev/null
  [[ ! -e "my file.txt" ]]                  || { echo "FAIL: not moved" >&2; return 1; }
  (trash "my file.txt" 2>/dev/null) && { echo "FAIL: missing file accepted" >&2; return 1; }
  echo again > "my file.txt"
  trash "my file.txt" sub/note.txt >/dev/null
  [[ $(ls "$TRASH_DIR" | wc -l) -eq 3 ]]    || { echo "FAIL: expected 3 items in trash" >&2; return 1; }
  (trash 2>/dev/null) && { echo "FAIL: no-arg accepted" >&2; return 1; }
  (trash / 2>/dev/null) && { echo "FAIL: / accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else trash "$@"; fi
