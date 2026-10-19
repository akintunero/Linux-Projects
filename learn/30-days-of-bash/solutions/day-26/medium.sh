#!/usr/bin/env bash
# Day 26 medium: a CSV report of busy servers, sorted by CPU, with a threshold passed safely. Needs jq.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01",    "cpu": 0.42},
  {"name": "cache 01", "cpu": 0.91},
  {"name": "db01",     "cpu": 0.77},
  {"name": "queue01",  "cpu": 0.10}
]}
EOF

threshold=0.5
echo "name,cpu"
jq -r --argjson t "$threshold" \
    '.servers | map(select(.cpu > $t)) | sort_by(-.cpu) | .[] | [.name, .cpu] | @csv' \
    "${work}/servers.json"

rm -rf -- "$work"
