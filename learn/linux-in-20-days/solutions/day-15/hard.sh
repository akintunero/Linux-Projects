#!/usr/bin/env bash
# Day 15 - Hard: unitlint.sh FILE - check a .service file before installing it.
#   ERROR (exit 1): systemd-analyze verify fails, or there is no ExecStart=
#   WARN  (exit 0): no Description=, a long-running service without Restart=, no [Install] section
# Usage: hard.sh FILE | hard.sh --self-test
# NEEDS-TOOL: systemd-analyze (exits 77 if missing). Read-only.
set -uo pipefail

unitlint() {
  local f=${1:-}
  [[ -f $f ]] || { echo "usage: unitlint FILE.service" >&2; return 2; }
  local errors=0

  if ! systemd-analyze --user verify "$f" >/dev/null 2>&1; then
    echo "ERROR: systemd-analyze verify fails (run it for details)"; errors=1
  fi
  grep -q '^ExecStart=' "$f" || { echo "ERROR: no ExecStart="; errors=1; }

  grep -q '^Description=' "$f" || echo "WARN: no Description="
  local type; type=$(sed -n 's/^Type=//p' "$f" | head -n 1)
  if [[ $type != oneshot ]] && ! grep -q '^Restart=' "$f"; then echo "WARN: long-running service without Restart="; fi
  grep -q '^\[Install\]' "$f" || echo "WARN: no [Install] section (it cannot be enabled)"
  return "$errors"
}

self_test() {
  command -v systemd-analyze >/dev/null || { echo "systemd-analyze missing" >&2; exit 77; }
  local w out rc; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  printf '[Unit]\nDescription=ok\n[Service]\nExecStart=/usr/bin/sleep 30\nRestart=on-failure\n[Install]\nWantedBy=default.target\n' > "$w/good.service"
  printf '[Service]\nExecStart=/usr/bin/sleep 30\n' > "$w/warn.service"
  printf '[Service]\nType=oneshot\nExecStart=backup.sh\nRestart=always\n' > "$w/bad.service"

  out=$(unitlint "$w/good.service"); rc=$?
  [[ $rc -eq 0 && -z $out ]] || { echo "FAIL good: rc=$rc out=$out" >&2; return 1; }
  out=$(unitlint "$w/warn.service"); rc=$?
  [[ $rc -eq 0 && $out == *"no Description"* && $out == *"without Restart"* && $out == *"no [Install]"* ]] \
    || { echo "FAIL warn: rc=$rc out=$out" >&2; return 1; }
  out=$(unitlint "$w/bad.service"); rc=$?
  [[ $rc -eq 1 && $out == *"ERROR: systemd-analyze"* ]] || { echo "FAIL bad: rc=$rc out=$out" >&2; return 1; }
  unitlint 2>/dev/null; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL usage rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else unitlint "$@"; fi
