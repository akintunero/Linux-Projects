#!/usr/bin/env bash
# Day 21 medium: pull every IPv4 address out of a log and count how often each appears.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/app.log" <<'EOF'
connect from 203.0.113.5 ok
connect from 198.51.100.7 refused
retry 203.0.113.5 then 192.0.2.44
proxy 10.0.0.1 forwarded 203.0.113.5 -> 192.0.2.44
version 1.2.3 started
EOF

echo "unique addresses, most frequent first:"
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "${work}/app.log" \
    | sort | uniq -c | sort -k1,1nr -k2,2 | awk '{ printf "%3d  %s\n", $1, $2 }'

echo "lines mentioning refused or failed: $(grep -cE 'refused|failed' "${work}/app.log")"

rm -rf -- "$work"
