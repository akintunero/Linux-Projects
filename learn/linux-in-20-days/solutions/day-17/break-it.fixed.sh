#!/usr/bin/env bash
# Day 17 - Break it, fixed. Bugs were:
#   1. `Host *` came first. ssh uses the FIRST value it finds for each option, so User nobody won over
#      User deploy. Put specific hosts first and `Host *` last.
#   2. `LocalForward 8080:localhost:80` is the command-line (-L) syntax. In a config file the two
#      parts are separated by a space: `LocalForward 8080 localhost:80`.
#   3. `Prot` is a typo for `Port`; ssh refuses the file ("Bad configuration option").
# NEEDS-TOOL: ssh (exits 77 if missing). Never connects: ssh -G only prints settings.
set -euo pipefail
command -v ssh >/dev/null || { echo "ssh missing" >&2; exit 77; }
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
cat > "$dir/config" <<'EOF'
Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
    LocalForward 8080 localhost:80

Host *
    User nobody
    ServerAliveInterval 30
EOF
out=$(ssh -F "$dir/config" -G web 2>&1)
grep -E '^(hostname|user|port|localforward) ' <<<"$out"

grep -qx 'user deploy' <<<"$out"                     || { echo "FAIL: user" >&2; exit 1; }
grep -qx 'port 2222' <<<"$out"                       || { echo "FAIL: port" >&2; exit 1; }
grep -qx 'hostname 192.0.2.10' <<<"$out"             || { echo "FAIL: hostname" >&2; exit 1; }
grep -qx 'localforward 8080 \[localhost\]:80' <<<"$out" || { echo "FAIL: forward" >&2; exit 1; }
grep -qiE 'bad configuration|line [0-9]+:' <<<"$out" && { echo "FAIL: ssh reported errors" >&2; exit 1; }
grep -qx 'serveraliveinterval 30' <<<"$out"          || { echo "FAIL: Host * default not applied" >&2; exit 1; }
echo PASS >&2
