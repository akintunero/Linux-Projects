#!/usr/bin/env bash
# Fixed: strip % and compare as integers, handle decimal load with awk, return non-zero on alert.
set -euo pipefail

cat > df.txt <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 100000 0 100% /
/dev/sdb1 500000 100000 400000 20% /data
EOF

echo '1.85 0.90 0.50' > load.txt

worst=0
note() { (( $1 > worst )) && worst="$1"; return 0; }

# Fix 1: strip % and compare numerically
use="$(awk 'NR==2 { u = $5; sub("%", "", u); print u }' df.txt)"
if (( use >= 90 )); then
    echo "ALERT: disk is ${use}% (critical)"
    note 2
fi

# Fix 2: compare decimal load using awk
load="$(cut -d' ' -f1 load.txt)"
load_alert="$(awk -v l="$load" 'BEGIN { print (l > 1.0) ? 1 : 0 }')"
if [[ $load_alert -eq 1 ]]; then
    echo "ALERT: load is ${load} (warning)"
    note 1
fi

# Fix 3: exit with the worst alert code
echo "overall status: exit ${worst}"
exit "$worst"
