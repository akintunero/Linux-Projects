#!/usr/bin/env bash
# Day 12 - Break it, fixed. Usage: break-it.fixed.sh HOST PORT | break-it.fixed.sh --self-test
# Bugs were:
#   1. ping tests ICMP, not the web service: many hosts block ping while serving HTTP, and a host
#      that answers ping may have nothing listening on the port.
#   2. `curl URL` returns 0 for an HTTP 404/500 (it only fails on connection problems) -> use -f.
#   3. No timeout: a firewall that drops packets makes curl wait for minutes -> -m 5 (and --connect-timeout).
# NEEDS-TOOL: curl (and python3 for the self-test); exits 77 if missing.
set -uo pipefail

check() {
  local host=$1 port=$2
  if curl -sf -m 5 --connect-timeout 3 -o /dev/null "http://$host:$port/"; then
    echo "web service is UP"
  else
    echo "web service is DOWN"; return 1
  fi
}

if [[ ${1:-} == --self-test ]]; then
  for t in curl python3; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
  w=$(mktemp -d); trap 'rm -rf "$w"' EXIT
  echo ok > "$w/index.html"
  port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$w" >/dev/null 2>&1 &
  srv=$!; sleep 1
  [[ $(check 127.0.0.1 "$port") == "web service is UP" ]] || { kill "$srv"; echo "FAIL: up" >&2; exit 1; }
  # Same server, a path that does not exist: curl without -f would call this "UP".
  if curl -sf -m 5 -o /dev/null "http://127.0.0.1:$port/missing"; then kill "$srv"; echo "FAIL: 404 accepted" >&2; exit 1; fi
  kill "$srv"; wait "$srv" 2>/dev/null
  [[ $(check 127.0.0.1 "$port") == "web service is DOWN" ]] || { echo "FAIL: down" >&2; exit 1; }
  echo PASS >&2
else
  check "$@"
fi
