#!/usr/bin/env bash
# Day 22 easy: test whether a TCP port accepts connections using only Bash (/dev/tcp).
# Uses a throwaway server on localhost.
set -euo pipefail

port_open() {
    local host="$1" port="$2"
    timeout 2 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null
}

port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

for _ in {1..50}; do
    port_open 127.0.0.1 "$port" && break
    sleep 0.1
done

if port_open 127.0.0.1 "$port"; then echo "test server port: open"; else echo "test server port: closed"; fi
if port_open 127.0.0.1 1; then echo "port 1: open"; else echo "port 1: closed"; fi
