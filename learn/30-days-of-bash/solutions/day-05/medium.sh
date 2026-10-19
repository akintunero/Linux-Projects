#!/usr/bin/env bash
# Day 05 medium: report hosts that are down; exit 1 if any are.
set -euo pipefail

work="$(mktemp -d)"
cat > "$work/servers.csv" <<'EOF'
host,ip,state
# staging
web01,10.0.0.5,up
db01,10.0.0.9,down
cache01,10.0.0.7,up
EOF

down=0
while IFS=, read -r host ip state; do
    [[ $host == host ]] && continue          # header line
    [[ $host == \#* ]] && continue           # comment line
    if [[ $state != up ]]; then
        echo "DOWN: $host ($ip)"
        down=$(( down + 1 ))
    fi
done < "$work/servers.csv"

rm -rf -- "$work"
echo "$down host(s) down"
if (( down > 0 )); then
    exit 1
fi
