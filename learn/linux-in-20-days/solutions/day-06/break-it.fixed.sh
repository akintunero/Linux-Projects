#!/usr/bin/env bash
# Day 06 - Break it, fixed. Bugs were:
#   1. `uniq -c` only merges ADJACENT duplicates -> sort first.
#   2. `sort -n` is ascending, so `head` showed the quietest clients -> sort -rn.
#   3. `grep 404` also matches the byte count 404 in the /login line -> anchor on the status column.
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

top=$(cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 2)
echo "$top"
errors=$(grep -c '" 404 ' access.log)
echo "404 responses: $errors"

[[ $(head -n 1 <<<"$top" | awk '{print $2}') == 203.0.113.5 && $errors -eq 2 ]] || { echo FAIL >&2; exit 1; }
echo PASS >&2
