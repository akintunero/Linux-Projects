#!/usr/bin/env bash
# Day 04 - Medium: a team directory with the setgid bit; files created inside are group-writable.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir shared
chgrp "$(id -gn)" shared          # in real life: the shared group, e.g. developers
chmod 2770 shared                 # 2 = setgid: new files inherit the directory's group
stat -c '%A %a %G' shared

(
  umask 007                       # new files: rw-rw----, new dirs: rwxrwx---
  touch shared/notes.txt
  mkdir shared/sub
)
stat -c '%A %a %G %n' shared/notes.txt shared/sub

[[ $(stat -c %A shared) == drwxrws--- ]]                || { echo "FAIL: setgid missing" >&2; exit 1; }
[[ $(stat -c %a shared/notes.txt) == 660 ]]             || { echo "FAIL: file mode" >&2; exit 1; }
[[ $(stat -c %G shared/notes.txt) == "$(stat -c %G shared)" ]] || { echo "FAIL: group" >&2; exit 1; }
[[ $(stat -c %A shared/sub) == drwxrws--- ]]            || { echo "FAIL: setgid not inherited" >&2; exit 1; }
echo PASS >&2
