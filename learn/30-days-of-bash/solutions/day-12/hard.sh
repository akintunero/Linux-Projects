#!/usr/bin/env bash
# Day 12 hard: traffic report - top 3 clients with their error rate, plus the busiest path.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:55:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:13:57:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:13:57:30 +0000] "GET /logo.png HTTP/1.1" 304 0
192.0.2.44 - - [10/Oct/2025:13:58:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:13:58:45 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:13:59:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:13:59:30 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "Top clients (requests, error rate):"
awk '
    { total[$1]++; if ($9 >= 400) errors[$1]++ }
    END {
        for (ip in total)
            printf "%d %s %.0f%%\n", total[ip], ip, 100 * errors[ip] / total[ip]
    }
' access.log | sort -k1,1nr -k2,2 | head -n 3 | awk '{ printf "  %-15s %2d requests, %s errors\n", $2, $1, $3 }'

echo "Busiest path:"
awk '{ hits[$7]++ } END { for (p in hits) print hits[p], p }' access.log | sort -k1,1nr -k2,2 | head -n 1

cd / && rm -rf -- "$work"
