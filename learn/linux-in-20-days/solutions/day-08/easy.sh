#!/usr/bin/env bash
# Day 08 - Easy: make an 8 MiB ext4 filesystem inside a regular file and read its block size.
# No root needed: mke2fs happily formats a plain file when given -F.
# NEEDS-TOOL: mkfs.ext4 and dumpe2fs (e2fsprogs; exits 77 if missing). Safe: temporary directory only.
set -euo pipefail
export PATH=$PATH:/usr/sbin:/sbin
command -v mkfs.ext4 >/dev/null && command -v dumpe2fs >/dev/null || { echo "e2fsprogs missing" >&2; exit 77; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

truncate -s 8M disk.img
mkfs.ext4 -q -F disk.img                 # -F: do not refuse because disk.img is not a block device
bs=$(dumpe2fs -h disk.img 2>/dev/null | awk -F: '/^Block size/ {gsub(/ /, "", $2); print $2}')
echo "block size: $bs"

[[ $bs -eq 1024 || $bs -eq 4096 ]] || { echo "FAIL: odd block size $bs" >&2; exit 1; }
file disk.img | grep -q 'ext4 filesystem' || { echo "FAIL: not ext4" >&2; exit 1; }
echo PASS >&2
