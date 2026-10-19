#!/usr/bin/env bash
# Day 08 - Hard: imgcheck.sh IMAGE - check an ext4 image file with e2fsck in read-only mode.
#   prints OK / DAMAGED / ERROR and exits 0 / 1 / 2.
# Usage: hard.sh IMAGE | hard.sh --self-test
# NEEDS-TOOL: e2fsprogs (exits 77 if missing). Never writes to IMAGE (e2fsck -n answers "no").
set -euo pipefail
export PATH=$PATH:/usr/sbin:/sbin

imgcheck() {
  local img=${1:?usage: imgcheck IMAGE}
  [[ -f $img ]] || { echo "ERROR: not a regular file: $img" >&2; return 2; }
  # -f force a full check, -n open read-only and answer "no" to every repair question.
  if e2fsck -fn "$img" >/dev/null 2>&1; then echo "OK"; return 0; fi
  echo "DAMAGED"; return 1
}

self_test() {
  command -v e2fsck >/dev/null && command -v mkfs.ext4 >/dev/null || { echo "e2fsprogs missing" >&2; exit 77; }
  local w; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  truncate -s 8M "$w/d.img"; mkfs.ext4 -q -F "$w/d.img"
  [[ $(imgcheck "$w/d.img") == OK ]]                     || { echo "FAIL: fresh image" >&2; return 1; }
  # Overwrite the group descriptor area (block 1 for 1k blocks / block 1 for 4k) to damage it.
  dd if=/dev/urandom of="$w/d.img" bs=4096 seek=1 count=1 conv=notrunc status=none
  local out rc=0; out=$(imgcheck "$w/d.img") || rc=$?
  [[ $out == DAMAGED && $rc -eq 1 ]]                     || { echo "FAIL: damage not detected ($out/$rc)" >&2; return 1; }
  rc=0; imgcheck "$w/none" >/dev/null 2>&1 || rc=$?
  [[ $rc -eq 2 ]]                                        || { echo "FAIL: missing file rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else imgcheck "$@"; fi
