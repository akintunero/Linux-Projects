#!/usr/bin/env bash
# Day 07 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: average size of successful (200) responses, then rename /var/www/index.html to /var/www/home.html.
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2026:13:55:36] "GET /var/www/index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" 404 209
192.0.2.44 - - [10/Oct/2026:13:57:12] "GET /var/www/index.html HTTP/1.1" 200 1043
EOF

awk '$8 = 200 {n++; s += $9} END {print s / n}' access.log
sed -i 's/var/www/index.html/var/www/home.html/' access.log
cat access.log
