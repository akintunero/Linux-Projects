#!/usr/bin/env bash
# Day 06 - Medium: the two busiest client IPs, busiest first, as "COUNT IP".
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2026:13:55:36] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:13:56:01] "POST /login HTTP/1.1" 302 404
192.0.2.44 - - [10/Oct/2026:13:57:12] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:57:30] "GET /about.html HTTP/1.1" 200 2310
203.0.113.5 - - [10/Oct/2026:13:58:02] "GET /api/data HTTP/1.1" 500 87
192.0.2.44 - - [10/Oct/2026:13:58:45] "GET /missing.css HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:14:01:10] "GET /index.html HTTP/1.1" 200 1043
EOF

out=$(cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 2 | awk '{print $1, $2}')
echo "$out"

[[ $(head -n 1 <<<"$out") == "4 203.0.113.5" ]] || { echo "FAIL: first line" >&2; exit 1; }
[[ $(wc -l <<<"$out") -eq 2 ]]                  || { echo "FAIL: need 2 lines" >&2; exit 1; }
echo PASS >&2
