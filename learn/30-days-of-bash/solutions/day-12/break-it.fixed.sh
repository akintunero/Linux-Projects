#!/usr/bin/env bash
# Fixed: pass shell values with -v (awk cannot see shell variables inside single quotes)
# and give awk the file name, otherwise it waits for standard input.
set -euo pipefail

printf '%s\n' \
  '100.64.0.9 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326' \
  '198.51.100.7 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153' \
  '192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 500 512' > access.log

limit=400
echo "clients with status >= $limit:"
awk -v limit="$limit" '$9 >= limit { print $1 }' access.log

echo "total bytes:"
awk '{ total += $10 } END { print total }' access.log
