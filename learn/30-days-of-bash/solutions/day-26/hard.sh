#!/usr/bin/env bash
# Day 26 hard: set_status NAME STATUS - update a JSON file atomically, validate it, summarise it.
# Needs jq. Temporary files only.
set -euo pipefail

set_status() {                                  # set_status FILE NAME STATUS
    local file="$1" name="$2" status="$3" tmp
    case "$status" in up|down|maintenance) ;; *) echo "bad status: ${status}" >&2; return 2 ;; esac
    jq -e --arg n "$name" '.servers[] | select(.name == $n)' "$file" >/dev/null \
        || { echo "no such server: ${name}" >&2; return 1; }
    tmp="$(mktemp "${file}.XXXXXX")"
    jq --arg n "$name" --arg s "$status" \
        '.servers |= map(if .name == $n then .status = $s else . end)' "$file" > "$tmp"
    jq -e . "$tmp" >/dev/null                   # the new file must still be valid JSON
    mv -- "$tmp" "$file"
}

summary() {
    jq -r '.servers | group_by(.status) | map("\(.[0].status): \(length)") | .[]' "$1"
}

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01", "status": "up"},
  {"name": "db01", "status": "down"},
  {"name": "cache 01", "status": "up"}
]}
EOF

echo "before:"; summary "${work}/servers.json"
set_status "${work}/servers.json" "db01" up
set_status "${work}/servers.json" "cache 01" maintenance
echo "after:"; summary "${work}/servers.json"

status=0; set_status "${work}/servers.json" "ghost" up 2>&1 || status=$?
echo "unknown server -> exit ${status}"
status=0; set_status "${work}/servers.json" "web01" exploded 2>&1 || status=$?
echo "bad status -> exit ${status}"
echo "leftover temp files: $(find "$work" -name 'servers.json.*' | wc -l)"

rm -rf -- "$work"
