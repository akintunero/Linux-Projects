#!/usr/bin/env bash
# Day 22 hard: wait_for_url with exponential back-off and an overall deadline.
# A throwaway server on localhost is started LATE on purpose, so the wait has something to do.
set -euo pipefail

# wait_for_url URL MAX_SECONDS  -> 0 when it answers with 2xx/3xx, 1 on timeout
wait_for_url() {
    local url="$1" deadline=$(( SECONDS + $2 )) delay=1 attempt=1
    while (( SECONDS < deadline )); do
        if curl -fsS -o /dev/null --max-time 2 "$url" 2>/dev/null; then
            echo "ready after ${attempt} attempt(s)" >&2
            return 0
        fi
        echo "attempt ${attempt} failed, retrying in ${delay}s" >&2
        sleep "$delay"
        attempt=$(( attempt + 1 ))
        (( delay < 4 )) && delay=$(( delay * 2 ))
    done
    return 1
}

work="$(mktemp -d)"
echo "ok" > "${work}/index.html"
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"

( sleep 2; exec python3 -m http.server "$port" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 ) &
starter=$!
trap 'kill "$starter" 2>/dev/null || true; pkill -f "http.server ${port}" 2>/dev/null || true; rm -rf -- "$work"' EXIT

if wait_for_url "http://127.0.0.1:${port}/" 15; then
    echo "service is ready"
else
    echo "service did not become ready" >&2
    exit 1
fi

echo "--- a service that never starts"
if wait_for_url "http://127.0.0.1:1/" 2; then
    echo "unexpectedly ready"
else
    echo "gave up after the deadline, as designed"
fi
