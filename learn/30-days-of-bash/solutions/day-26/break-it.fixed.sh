#!/usr/bin/env bash
# Fixed: -r plus mapfile for names with spaces, --arg for shell values, a temp file for in-place edits.
set -euo pipefail

echo '{"servers":[{"name":"cache 01"},{"name":"web01"}]}' > s.json

mapfile -t names < <(jq -r '.servers[].name' s.json)
for n in "${names[@]}"; do
    echo "server: $n"
done

want="web01"
jq --arg n "$want" '.servers[] | select(.name == $n)' s.json

jq '.servers |= map(.checked = true)' s.json > s.json.new && mv s.json.new s.json
echo "s.json now has checked=$(jq '[.servers[].checked] | all' s.json)"
