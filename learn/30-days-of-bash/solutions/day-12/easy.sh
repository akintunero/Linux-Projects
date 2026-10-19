#!/usr/bin/env bash
# Day 12 easy: list the client and path of every 404.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:13:56:40 +0000] "GET /old-page HTTP/1.1" 404 153
EOF

awk '$9 == 404 { print $1, $7 }' access.log

cd / && rm -rf -- "$work"
