#!/usr/bin/env bash
# Day 05 - Break it, fixed. Bugs were:
#   1. No `wq`: in -es (silent ex) mode nothing is saved unless you write the buffer.
#   2. `80` also matches inside 8080 (it would become 808080) -> match whole words with \<80\>.
#   3. Without the g flag only the first match on each line changes (proxy=80 80).
# NEEDS-TOOL: vim (exits 77 if missing). Safe: temporary directory only.
set -euo pipefail
command -v vim >/dev/null || { echo "vim not installed" >&2; exit 77; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

printf 'port=80\nbackup_port=8080\nproxy=80 80\n' > app.conf
vim -es -c '%s/\<80\>/8080/g' -c 'wq' app.conf
cat app.conf

[[ $(cat app.conf) == $'port=8080\nbackup_port=8080\nproxy=8080 8080' ]] || { echo FAIL >&2; exit 1; }
echo PASS >&2
