#!/usr/bin/env bash
# Day 11 medium: anonymise client IPs in an access log by masking the last octet.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
EOF

sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+/\1.x/' access.log > access.anon.log

cat access.anon.log
echo "--- lines with a bare IP left: $(grep -cE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ' access.anon.log || true)"

cd / && rm -rf -- "$work"
