#!/usr/bin/env bash
# Day 14 - Break it, fixed. Bugs were:
#   1. `rsync -a site backup` (no trailing slash) copies the DIRECTORY, giving backup/site/...;
#      `site/` copies its CONTENTS. Quote the variables too.
#   2. `tar -czf x.tgz $PWD/site` stores an absolute path, so a restore tries to write to the original
#      location. Store relative names: tar -C parent site.
#   3. No error checking: `echo "backup ok"` ran even when rsync or tar failed -> set -e (or test each step).
# NEEDS-TOOL: rsync (exits 77 if missing). Self-test: break-it.fixed.sh --self-test
set -euo pipefail

backup() {
  local src=${1:-site} dest=${2:-backup}
  [[ -d $src ]] || { echo "source is not a directory: $src" >&2; return 1; }
  mkdir -p -- "$dest"
  rsync -a -- "$src"/ "$dest"/
  tar -czf "$dest/$(basename -- "$src").tgz" -C "$(dirname -- "$src")" "$(basename -- "$src")"
  echo "backup ok"
}

if [[ ${1:-} == --self-test ]]; then
  command -v rsync >/dev/null || { echo "rsync missing" >&2; exit 77; }
  w=$(mktemp -d); trap 'rm -rf "$w"' EXIT; cd "$w"
  mkdir site; echo hi > site/index.html
  [[ $(backup site backup) == "backup ok" ]]                || { echo "FAIL: ok" >&2; exit 1; }
  [[ -f backup/index.html && ! -e backup/site ]]            || { echo "FAIL: nesting" >&2; exit 1; }
  ! tar -tzf backup/site.tgz | grep -q '^/'                 || { echo "FAIL: absolute path" >&2; exit 1; }
  tar -tzf backup/site.tgz | grep -qx 'site/index.html'     || { echo "FAIL: relative member" >&2; exit 1; }
  out=$(backup missing backup2 2>/dev/null) && { echo "FAIL: missing source reported ok" >&2; exit 1; }
  [[ $out != *"backup ok"* ]]                               || { echo "FAIL: false ok" >&2; exit 1; }
  echo PASS >&2
else
  backup "$@"
fi
