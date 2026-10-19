#!/usr/bin/env bash
# Day 20 - Break it, fixed. Bugs were:
#   1. `ExecStart=python3 ...` is not an absolute path.
#   2. `Type=oneshot` with `Restart=always` is refused; a server is Type=simple (the default): delete the line.
#   3. `WantedBy=multi-user.target` does not exist in a user manager; user units use default.target
#      (a unit that is never wanted by anything will not start at login even though verify may stay quiet).
# NEEDS-TOOL: systemd-analyze, python3 (exits 77 if missing). Writes only to a temporary directory.
set -euo pipefail
command -v systemd-analyze >/dev/null && command -v python3 >/dev/null || { echo "tool missing" >&2; exit 77; }
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
cat > "$dir/web.service" <<EOF
[Unit]
Description=Capstone web

[Service]
ExecStart=$(command -v python3) -m http.server 8080 --bind 127.0.0.1 --directory %h/site
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
EOF
out=$(systemd-analyze --user verify "$dir/web.service" 2>&1) && rc=0 || rc=$?
echo "verify exit status: $rc"
[[ $rc -eq 0 && -z $out ]] || { echo "FAIL: $out" >&2; exit 1; }
grep -q '^WantedBy=default.target' "$dir/web.service" || { echo "FAIL: wrong target" >&2; exit 1; }
echo PASS >&2
