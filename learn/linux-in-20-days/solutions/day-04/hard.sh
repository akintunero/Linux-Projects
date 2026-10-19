#!/usr/bin/env bash
# Day 04 - Hard: permaudit.sh DIR - report risky permissions.
#   world-writable files, world-writable directories without the sticky bit, setuid/setgid files.
# Usage: hard.sh DIR | hard.sh --self-test
# Safe: read-only on DIR.
set -euo pipefail

permaudit() {
  local dir=${1:?usage: permaudit DIR}
  [[ -d $dir ]] || { echo "not a directory: $dir" >&2; return 2; }
  find "$dir" -type f -perm -0002 -printf 'world-writable file: %p\n' | sort
  find "$dir" -type d -perm -0002 ! -perm -1000 -printf 'world-writable dir without sticky bit: %p\n' | sort
  find "$dir" -type f \( -perm -4000 -o -perm -2000 \) -printf 'setuid/setgid file: %p\n' | sort
}

self_test() {
  local w out; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  mkdir "$w/ok" "$w/bad" "$w/tmpish"
  touch "$w/ok/fine" "$w/bad/leaky" "$w/bad/suid"
  chmod 644 "$w/ok/fine"; chmod 666 "$w/bad/leaky"; chmod 4755 "$w/bad/suid"
  chmod 777 "$w/bad"; chmod 1777 "$w/tmpish"
  out=$(permaudit "$w")
  grep -q 'world-writable file: .*/leaky' <<<"$out"        || { echo "FAIL: leaky" >&2; return 1; }
  grep -q 'without sticky bit: .*/bad$' <<<"$out"          || { echo "FAIL: bad dir" >&2; return 1; }
  grep -q 'tmpish' <<<"$out"                               && { echo "FAIL: sticky dir flagged" >&2; return 1; }
  grep -q 'setuid/setgid file: .*/suid' <<<"$out"          || { echo "FAIL: suid" >&2; return 1; }
  grep -q '/fine' <<<"$out"                                && { echo "FAIL: fine flagged" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else permaudit "$@"; fi
