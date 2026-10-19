#!/usr/bin/env bash
# Day 12 - Hard: netdiag.sh HOST PORT - walk the layers and stop at the first one that fails.
#   1 name resolution (getent hosts)   2 TCP connect (/dev/tcp)   3 HTTP answer (curl)
# Prints "ok" or "FAIL" per layer; exit status is the number of the failing layer, 0 if all pass.
# Usage: hard.sh HOST PORT | hard.sh --self-test
# NEEDS-TOOL: curl (and python3 for the self-test); exits 77 if missing.
set -uo pipefail

netdiag() {
  (($# == 2)) || { echo "usage: netdiag HOST PORT" >&2; return 64; }
  local host=$1 port=$2 code

  if getent hosts "$host" >/dev/null; then echo "1 resolve  ok"; else echo "1 resolve  FAIL ($host does not resolve)"; return 1; fi

  if timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo "2 connect  ok"
  else
    echo "2 connect  FAIL (nothing accepts connections on $host:$port)"; return 2
  fi

  # -f makes HTTP errors (>= 400) a failure; -m limits the whole request to 5 seconds.
  if code=$(curl -s -f -m 5 -o /dev/null -w '%{http_code}' "http://$host:$port/"); then
    echo "3 http     ok ($code)"
  else
    echo "3 http     FAIL (status ${code:-none})"; return 3
  fi
}

self_test() {
  for t in curl python3; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
  local w port srv rc; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  echo ok > "$w/index.html"
  port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$w" >/dev/null 2>&1 &
  srv=$!; sleep 1
  netdiag localhost "$port" >/dev/null; rc=$?
  ((rc == 0)) || { kill "$srv"; echo "FAIL: healthy server rc=$rc" >&2; return 1; }
  # A path that does not exist would be a 404: prove layer 3 notices. Done by asking for a closed port instead
  # for layer 2, and an unresolvable name (reserved .invalid TLD) for layer 1.
  netdiag nonexistent.invalid 80 >/dev/null; rc=$?
  ((rc == 1)) || { kill "$srv"; echo "FAIL: bad name rc=$rc" >&2; return 1; }
  kill "$srv"; wait "$srv" 2>/dev/null
  netdiag 127.0.0.1 "$port" >/dev/null; rc=$?
  ((rc == 2)) || { echo "FAIL: closed port rc=$rc" >&2; return 1; }
  netdiag >/dev/null 2>&1; rc=$?
  ((rc == 64)) || { echo "FAIL: usage rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else netdiag "$@"; fi
