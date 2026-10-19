#!/usr/bin/env bash
# Day 19 - Medium: "Address already in use" - find WHO holds the port and stop only that process.
# Starts two harmless local servers, one of which plays the guilty party. A careless `pkill python3`
# would kill both; the PID taken from `ss -ltnp` kills exactly one.
# NEEDS-TOOL: python3, ss (exits 77 if missing). Binds 127.0.0.1 only.
set -uo pipefail
for t in python3 ss; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
work=$(mktemp -d); trap 'kill "${guilty:-0}" "${innocent:-0}" 2>/dev/null; rm -rf "$work"' EXIT

freeport() { python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])'; }
p1=$(freeport); p2=$(freeport)
python3 -m http.server "$p1" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 & guilty=$!
python3 -m http.server "$p2" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 & innocent=$!
sleep 1

# Symptom: starting something else on p1 fails.
err=$(python3 -m http.server "$p1" --bind 127.0.0.1 --directory "$work" 2>&1)   # exits at once with an error
[[ $err == *"in use"* ]] || { echo "FAIL: expected 'Address already in use'" >&2; exit 1; }

# Diagnose: which PID listens on p1? (-p needs the process to be yours, or root)
holder=$(ss -ltnp "sport = :$p1" | grep -o 'pid=[0-9]*' | head -n 1 | cut -d= -f2)
echo "port $p1 is held by PID ${holder:-unknown}: $(ps -o args= -p "${holder:-0}" | cut -c1-30)..."
[[ $holder == "$guilty" ]] || { echo "FAIL: found '$holder', expected '$guilty'" >&2; exit 1; }

# Fix: stop exactly that process and nothing else.
kill "$holder"; sleep 0.5
ss -ltn "sport = :$p1" | grep -q LISTEN && { echo "FAIL: port still busy" >&2; exit 1; }
ss -ltn "sport = :$p2" | grep -q LISTEN || { echo "FAIL: innocent server was killed" >&2; exit 1; }
echo "port $p1 is free; the other server is still running"
echo PASS >&2
