#!/usr/bin/env bash
# Day 14 - Hard: snapshot.sh SRC DEST [KEEP] - rsync snapshots that share unchanged files via hard links.
#   Each run creates DEST/<timestamp>; unchanged files are hard links to the previous snapshot, so ten
#   daily snapshots cost little more than one. Only the newest KEEP (default 7) snapshots are kept.
#   A snapshot is built in DEST/.partial and renamed when complete, so a crash never leaves a half backup.
# Test override: NOW=20260101T000000 sets the snapshot name.
# Usage: hard.sh SRC DEST [KEEP] | hard.sh --self-test
# NEEDS-TOOL: rsync (exits 77 if missing). Writes only inside DEST.
set -euo pipefail

snapshot() {
  local src=${1:-} dest=${2:-} keep=${3:-7}
  [[ -d $src ]] || { echo "source is not a directory: $src" >&2; return 2; }
  [[ -n $dest ]] || { echo "usage: snapshot SRC DEST [KEEP]" >&2; return 2; }
  [[ $keep =~ ^[1-9][0-9]*$ ]] || { echo "KEEP must be a positive integer" >&2; return 2; }
  mkdir -p -- "$dest"
  local name=${NOW:-$(date +%Y%m%dT%H%M%S)} prev link=()
  prev=$(find "$dest" -mindepth 1 -maxdepth 1 -type d -name '2*' | sort | tail -n 1)
  [[ -z $prev ]] || link=(--link-dest="$prev")

  rm -rf -- "${dest:?}/.partial"
  if ! rsync -a "${link[@]}" -- "$src"/ "$dest/.partial/"; then
    rm -rf -- "${dest:?}/.partial"; echo "rsync failed" >&2; return 1
  fi
  mv -- "$dest/.partial" "$dest/$name"

  # Prune: list snapshot names, newest last, delete everything older than the newest KEEP.
  local count; count=$(find "$dest" -mindepth 1 -maxdepth 1 -type d -name '2*' | wc -l)
  if ((count > keep)); then
    find "$dest" -mindepth 1 -maxdepth 1 -type d -name '2*' | sort | head -n "$((count - keep))" \
      | while IFS= read -r old; do rm -rf -- "$old"; done
  fi
  echo "snapshot: $dest/$name"
}

self_test() {
  command -v rsync >/dev/null || { echo "rsync missing" >&2; exit 77; }
  local w; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  mkdir -p "$w/src/css"; echo same > "$w/src/css/main.css"; echo v1 > "$w/src/index.html"

  NOW=20260101T000000 snapshot "$w/src" "$w/dest" 2 >/dev/null
  # rsync's quick check compares size and modification time; "v2" has the same size as "v1" and the
  # same second, so it would be treated as unchanged. Use different content length in the test.
  echo version-two > "$w/src/index.html"
  NOW=20260102T000000 snapshot "$w/src" "$w/dest" 2 >/dev/null

  [[ $(stat -c %h "$w/dest/20260102T000000/css/main.css") -eq 2 ]] || { echo "FAIL: unchanged file not hard-linked" >&2; return 1; }
  [[ $(stat -c %i "$w/dest/20260101T000000/index.html") != $(stat -c %i "$w/dest/20260102T000000/index.html") ]] \
    || { echo "FAIL: changed file shares an inode" >&2; return 1; }
  [[ $(cat "$w/dest/20260101T000000/index.html") == v1 ]] || { echo "FAIL: old snapshot altered" >&2; return 1; }

  NOW=20260103T000000 snapshot "$w/src" "$w/dest" 2 >/dev/null
  [[ ! -d $w/dest/20260101T000000 && -d $w/dest/20260102T000000 && -d $w/dest/20260103T000000 ]] \
    || { echo "FAIL: pruning wrong: $(ls "$w/dest")" >&2; return 1; }
  [[ ! -e $w/dest/.partial ]] || { echo "FAIL: partial left" >&2; return 1; }
  snapshot "$w/nope" "$w/dest" 2>/dev/null && { echo "FAIL: missing source accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else snapshot "$@"; fi
