#!/usr/bin/env bash
# Day 12 - Medium: portcheck.sh HOST PORT - is a TCP port accepting connections? Uses bash's /dev/tcp,
# so it works even where nc is not installed. Exit 0 open, 1 closed/timeout, 2 usage.
# Usage: medium.sh HOST PORT | medium.sh --self-test
# NEEDS-TOOL: python3 for the self-test only (exits 77 if missing).
set -uo pipefail

portcheck() {
  (($# == 2)) || { echo "usage: portcheck HOST PORT" >&2; return 2; }
  [[ $2 =~ ^[0-9]+$ ]] && (($2 >= 1 && $2 <= 65535)) || { echo "bad port: $2" >&2; return 2; }
  # The redirection opens a TCP connection; timeout stops a firewall from making us wait for ever.
  timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$1" "$2" 2>/dev/null
}

self_test() {
  command -v python3 >/dev/null || { echo "python3 missing" >&2; exit 77; }
  local port srv rc
  port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
  portcheck 127.0.0.1 "$port"; rc=$?
  ((rc == 1)) || { echo "FAIL: closed port reported rc=$rc" >&2; return 1; }
  python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
  srv=$!
  sleep 1
  portcheck 127.0.0.1 "$port"; rc=$?
  kill "$srv" 2>/dev/null; wait "$srv" 2>/dev/null
  ((rc == 0)) || { echo "FAIL: open port reported rc=$rc" >&2; return 1; }
  portcheck 127.0.0.1 99999 2>/dev/null; rc=$?
  ((rc == 2)) || { echo "FAIL: bad port rc=$rc" >&2; return 1; }
  portcheck 2>/dev/null; rc=$?
  ((rc == 2)) || { echo "FAIL: usage rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else portcheck "$@"; fi
