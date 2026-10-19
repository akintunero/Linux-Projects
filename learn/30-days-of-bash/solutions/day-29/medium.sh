#!/usr/bin/env bash
# Day 29 medium: a text histogram of requests per hour.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/access.log" <<'EOF'
1.1.1.1 - - [10/Oct/2025:13:05:36 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:13:15:40 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:13:25:01 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:14:06:12 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:14:07:03 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:17:30 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:18:11 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:19:30 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:20:00 +0000] "GET /a HTTP/1.1" 200 1
EOF

echo "requests per hour"
cut -d'[' -f2 "${work}/access.log" | cut -d: -f2 | sort | uniq -c |
    while read -r count hour; do
        bar="$(printf '%*s' "$count" '' | tr ' ' '#')"
        printf '%s:00 %-6s %d\n' "$hour" "$bar" "$count"
    done

rm -rf -- "$work"
