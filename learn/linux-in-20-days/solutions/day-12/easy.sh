#!/usr/bin/env bash
# Day 12 - Easy: start a local web server, prove it is listening with ss, then fetch from it.
# Binds to 127.0.0.1 only, on a free port, and stops it afterwards.
# NEEDS-TOOL: python3, ss, curl (exits 77 if missing).
set -euo pipefail
for t in python3 ss curl; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
work=$(mktemp -d); cd "$work"
echo "hello from day 12" > index.html

port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
srv=$!
trap 'kill "$srv" 2>/dev/null || true; rm -rf "$work"' EXIT

for _ in 1 2 3 4 5 6 7 8 9 10; do                    # wait up to ~2 s for the listener
  ss -ltn "sport = :$port" | grep -q LISTEN && break
  sleep 0.2
done

ss -ltn "sport = :$port" | awk 'NR > 1 {print $1, $4}' | sed "s/:$port/:PORT/"
body=$(curl -s "http://127.0.0.1:$port/")
code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/")
echo "$code $body"

[[ $code == 200 && $body == "hello from day 12" ]] || { echo "FAIL" >&2; exit 1; }
echo PASS >&2
