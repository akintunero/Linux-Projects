#!/usr/bin/env bash
# Day 15 - Easy: write a user service unit, verify it, start it, read its journal, stop it, clean up.
# Uses `systemctl --user`, so no root is needed. Installs ~/.config/systemd/user/linux20-d15-easy.service
# for the duration of the script and removes it again.
# NEEDS-TOOL: a running systemd user manager (exits 77 if missing).
set -euo pipefail
systemctl --user is-system-running >/dev/null 2>&1 || [[ $(systemctl --user is-system-running 2>/dev/null) == degraded ]] \
  || { echo "no systemd user manager available" >&2; exit 77; }

unit=linux20-d15-easy.service
dir=$HOME/.config/systemd/user
mkdir -p "$dir"
cleanup() {
  systemctl --user stop "$unit" 2>/dev/null || true
  rm -f "$dir/$unit"
  systemctl --user daemon-reload
}
trap cleanup EXIT

cat > "$dir/$unit" <<'EOF'
[Unit]
Description=Linux in 20 days: hello service

[Service]
ExecStart=/bin/sh -c 'echo "hello from the unit"; sleep 30'

[Install]
WantedBy=default.target
EOF

systemd-analyze --user verify "$dir/$unit"
systemctl --user daemon-reload
systemctl --user start "$unit"
sleep 1
state=$(systemctl --user is-active "$unit")
echo "state: $state"
journalctl --user -u "$unit" --no-pager -o cat | grep -x 'hello from the unit'

[[ $state == active ]] || { echo "FAIL: not active" >&2; exit 1; }
echo PASS >&2
