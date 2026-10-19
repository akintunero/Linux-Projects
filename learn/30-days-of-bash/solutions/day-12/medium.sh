#!/usr/bin/env bash
# Day 12 medium: requests and bytes per status code, sorted by code.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:55:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
198.51.100.7 - - [10/Oct/2025:13:57:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:13:57:30 +0000] "GET /logo.png HTTP/1.1" 304 0
EOF

printf '%-7s %8s %10s\n' STATUS REQUESTS BYTES
awk '
    { count[$9]++; bytes[$9] += $10 }
    END { for (s in count) printf "%-7s %8d %10d\n", s, count[s], bytes[s] }
' access.log | sort -n

cd / && rm -rf -- "$work"
