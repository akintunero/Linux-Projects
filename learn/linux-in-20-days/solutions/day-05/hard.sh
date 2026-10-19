#!/usr/bin/env bash
# Day 05 - Hard: tidy.sh FILE - back up FILE to FILE.bak, drop comment and blank lines,
# and make every remaining line end in exactly one semicolon. Safe to run twice.
# Usage: hard.sh FILE | hard.sh --self-test
# NEEDS-TOOL: vim (exits 77 if missing). Edits FILE in place (after making the backup).
set -euo pipefail

tidy() {
  local f=${1:?usage: tidy FILE}
  [[ -f $f ]] || { echo "not a file: $f" >&2; return 2; }
  cp -p -- "$f" "$f.bak"
  # ex commands: delete comment lines, delete blank lines, make each line end in one ';'
  vim -es -c 'g/^\s*#/d' -c 'g/^\s*$/d' -c '%s/;*$/;/' -c 'wq' -- "$f"
}

self_test() {
  command -v vim >/dev/null || { echo "vim not installed" >&2; exit 77; }
  local w; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  printf '# header\nserver=a\n\nport=80;\n' > "$w/c.conf"
  tidy "$w/c.conf"
  [[ $(cat "$w/c.conf") == $'server=a;\nport=80;' ]] || { echo "FAIL: content" >&2; return 1; }
  [[ -f $w/c.conf.bak ]] && grep -q '^# header' "$w/c.conf.bak" || { echo "FAIL: backup" >&2; return 1; }
  tidy "$w/c.conf"                                   # idempotent
  [[ $(cat "$w/c.conf") == $'server=a;\nport=80;' ]] || { echo "FAIL: second run changed file" >&2; return 1; }
  (tidy "$w/missing" 2>/dev/null) && { echo "FAIL: missing file accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else tidy "$@"; fi
