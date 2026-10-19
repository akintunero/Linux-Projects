#!/usr/bin/env bash
# Day 22 medium: http_status URL prints the status code; check_url turns it into OK/FAIL.
# Uses a throwaway server on localhost.
set -euo pipefail

http_status() {
    # %{http_code} is 000 when no HTTP response was received at all
    curl -s -o /dev/null --max-time 3 -w '%{http_code}' "$1" || true
}

check_url() {
    local url="$1" code
    code="$(http_status "$url")"
    case "$code" in
        2??|3??) printf '%-4s OK    %s\n' "$code" "$2"; return 0 ;;
        *)       printf '%-4s FAIL  %s\n' "$code" "$2"; return 1 ;;
    esac
}

work="$(mktemp -d)"
echo "ok" > "${work}/index.html"
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; rm -rf -- "$work"' EXIT

until curl -s -o /dev/null "http://127.0.0.1:${port}/"; do sleep 0.1; done

failed=0
check_url "http://127.0.0.1:${port}/"        "home page"        || failed=$(( failed + 1 ))
check_url "http://127.0.0.1:${port}/missing" "missing page"     || failed=$(( failed + 1 ))
check_url "http://127.0.0.1:1/"              "nothing listening" || failed=$(( failed + 1 ))

echo "${failed} check(s) failed"
