#!/usr/bin/env bash
# Day 29 hard: error triage report - counts by class, top failing paths, noisiest owners.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:14:07:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:14:17:30 +0000] "GET /logo.png HTTP/1.1" 200 404
192.0.2.44 - - [10/Oct/2025:14:18:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:15:08:45 +0000] "GET /api/items HTTP/1.1" 503 87
203.0.113.5 - - [10/Oct/2025:15:09:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:15:20:00 +0000] "GET /old-page HTTP/1.1" 404 153
EOF
printf '%s\n' '192.0.2.44 office' '198.51.100.7 partner' '203.0.113.5 customer' > owners.txt

# Status code is the 3rd-from-last space-separated field; the status class is its first digit.
total="$(wc -l < access.log)"
errors="$(grep -cE '" [45][0-9]{2} ' access.log)"
echo "requests: ${total}, errors: ${errors} ($(( errors * 100 / total ))%)"

echo "--- errors by class"
grep -oE '" [45][0-9]{2} ' access.log | tr -d '" ' | cut -c1 | sort | uniq -c |
    sed -e 's/ 4$/ 4xx client errors/' -e 's/ 5$/ 5xx server errors/'

echo "--- failing paths, worst first"
grep -E '" [45][0-9]{2} ' access.log | cut -d'"' -f2 | cut -d' ' -f2 | sort | uniq -c | sort -k1,1nr -k2

echo "--- who causes the errors"
grep -E '" [45][0-9]{2} ' access.log | cut -d' ' -f1 | sort | uniq -c | awk '{ print $2, $1 }' | sort > err-counts.txt
join owners.txt err-counts.txt | sort -k3,3nr | column -t

cd / && rm -rf -- "$work"
