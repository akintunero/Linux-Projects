#!/usr/bin/env bash
# Day 07 - Break it, fixed. Bugs were:
#   1. `$8 = 200` ASSIGNS 200 (always true, and corrupts the status field) -> compare with ==.
#   2. `s / n` divides by zero when no line matches -> guard with `n > 0`.
#   3. The sed pattern contains / but uses / as the delimiter -> choose another delimiter such as #.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2026:13:55:36] "GET /var/www/index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" 404 209
192.0.2.44 - - [10/Oct/2026:13:57:12] "GET /var/www/index.html HTTP/1.1" 200 1043
EOF

avg=$(awk '$8 == 200 {n++; s += $9} END {if (n > 0) print s / n; else print 0}' access.log)
echo "$avg"
sed -i 's#/var/www/index.html#/var/www/home.html#' access.log
cat access.log

[[ $avg == 1043 ]]                    || { echo "FAIL: avg $avg" >&2; exit 1; }
grep -q '/var/www/home.html' access.log || { echo "FAIL: sed" >&2; exit 1; }
echo PASS >&2
