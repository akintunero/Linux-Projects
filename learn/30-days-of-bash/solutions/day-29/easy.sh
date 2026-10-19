#!/usr/bin/env bash
# Day 29 easy: the three most requested paths.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/access.log" <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:14:07:03 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:14:17:30 +0000] "POST /api/login HTTP/1.1" 401 64
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "top paths:"
cut -d'"' -f2 "${work}/access.log" | cut -d' ' -f2 | sort | uniq -c | sort -k1,1nr -k2 | head -n 3

rm -rf -- "$work"
