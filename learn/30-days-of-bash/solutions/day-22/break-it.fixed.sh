#!/usr/bin/env bash
# Fixed: wait for the port instead of sleeping, make curl fail on HTTP errors (-f),
# and clean up the server with a trap.
set -euo pipefail

port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
mkdir site
echo "welcome" > site/index.html
python3 -m http.server "$port" --bind 127.0.0.1 --directory site >/dev/null 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT

until curl -s -o /dev/null "http://127.0.0.1:${port}/"; do sleep 0.1; done

if curl -fsS "http://127.0.0.1:${port}/report.html" -o report.html 2>/dev/null; then
    echo "download ok"
else
    echo "download failed: no such page"
fi
[[ -f report.html ]] && rm -f report.html
echo "report.html exists: $([[ -f report.html ]] && echo yes || echo no)"
