#!/usr/bin/env bash
# Day 15 - Medium: prove Restart=on-failure works. A transient user service crashes; systemd restarts it.
# Uses `systemd-run --user` (a unit that exists only in memory), so nothing is written to disk.
# NEEDS-TOOL: a running systemd user manager (exits 77 if missing).
set -euo pipefail
[[ $(systemctl --user is-system-running 2>/dev/null) =~ ^(running|degraded)$ ]] \
  || { echo "no systemd user manager available" >&2; exit 77; }

name=linux20-d15-crashy
cleanup() { systemctl --user stop "$name.service" 2>/dev/null || true; systemctl --user reset-failed "$name.service" 2>/dev/null || true; }
trap cleanup EXIT

# The service lives 1 second, then exits with status 1 (a failure), so systemd restarts it after 1 s.
systemd-run --user --unit="$name" --quiet \
  --property=Restart=on-failure --property=RestartSec=1 \
  /bin/sh -c 'sleep 1; exit 1'

restarts=0
for _ in $(seq 1 15); do                        # wait up to ~7 s for at least one restart
  restarts=$(systemctl --user show -p NRestarts --value "$name.service")
  ((restarts >= 1)) && break
  sleep 0.5
done
echo "NRestarts=$restarts"

((restarts >= 1)) || { echo "FAIL: service was not restarted" >&2; exit 1; }
echo PASS >&2
