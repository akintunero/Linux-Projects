#!/usr/bin/env bash
# Day 05 - Medium: in app.conf change the whole word 80 to 8080 and delete comment lines.
# Interactive vim keys:  :%s/\<80\>/8080/g  Enter   then   :g/^#/d  Enter   then   :wq  Enter
# NEEDS-TOOL: vim (exits 77 if missing). Safe: temporary directory only.
set -euo pipefail
command -v vim >/dev/null || { echo "vim not installed" >&2; exit 77; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

printf 'server=app.example.com\nport=80\n# old setting\nbackup_port=8080\n' > app.conf
vim -es -c '%s/\<80\>/8080/g' -c 'g/^#/d' -c 'wq' app.conf
cat app.conf

grep -qx 'port=8080' app.conf           || { echo "FAIL: port" >&2; exit 1; }
grep -qx 'backup_port=8080' app.conf    || { echo "FAIL: backup_port was damaged" >&2; exit 1; }
! grep -q '^#' app.conf                 || { echo "FAIL: comment left" >&2; exit 1; }
echo PASS >&2
