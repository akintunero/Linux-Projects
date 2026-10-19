#!/usr/bin/env bash
# Fixed: skip the header, strip the % sign, compare as numbers, read lines instead of words.
set -euo pipefail

cat > df.txt <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 150000 50000 75% /var
EOF

while read -r mount use; do
    if (( use > 90 )); then
        echo "ALERT: ${mount} is at ${use}%"
    fi
done < <(awk 'NR > 1 { u = $5; sub("%", "", u); print $6, u }' df.txt)
