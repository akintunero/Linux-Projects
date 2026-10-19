#!/usr/bin/env bash
# Day 26 easy: list the servers that are down. Needs jq.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01", "status": "up"},
  {"name": "db 01", "status": "down"},
  {"name": "queue01", "status": "down"}
]}
EOF

echo "servers that are down:"
jq -r '.servers[] | select(.status == "down") | "  " + .name' "${work}/servers.json"
echo "count: $(jq '[.servers[] | select(.status == "down")] | length' "${work}/servers.json")"

rm -rf -- "$work"
