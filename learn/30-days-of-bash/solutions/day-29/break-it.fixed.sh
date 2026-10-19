#!/usr/bin/env bash
# Fixed: match the status column, not any "404" in the line; sort BEFORE uniq; sort counts numerically.
set -euo pipefail

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 404
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /missing HTTP/1.1" 404 153
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /index.html HTTP/1.1" 200 2326
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:14:07:03 +0000] "GET /about.html HTTP/1.1" 200 1840
EOF

echo "404 responses: $(grep -c '" 404 ' access.log)"

echo "top clients:"
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 2
