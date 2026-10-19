#!/usr/bin/env bash
# Day 28 hard: a combined health check with a table and a monitoring-style exit code
# (0 OK, 1 WARN, 2 CRIT = the worst result). Read-only. Runs on fixtures here;
# remove the fixture arguments to check the machine you are on.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

printf 'MemTotal: 8000000 kB\nMemAvailable: 1200000 kB\n' > "${work}/meminfo"
echo '3.50 2.10 1.00 2/300 12345' > "${work}/loadavg"
cat > "${work}/df" <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 170000 30000 85% /var/lib/db
EOF

declare -A WARN=([mem]=80 [load]=0.7 [disk]=80)
declare -A CRIT=([mem]=90 [load]=1.0 [disk]=90)
worst=0

level_of() {                                  # level_of KEY VALUE -> 0 OK, 1 WARN, 2 CRIT
    awk -v v="$2" -v w="${WARN[$1]}" -v c="${CRIT[$1]}" 'BEGIN { print (v >= c) ? 2 : (v >= w) ? 1 : 0 }'
}
label() { case "$1" in 0) echo OK ;; 1) echo WARN ;; *) echo CRIT ;; esac; }

row() {                                       # row CHECK DETAIL LEVEL
    printf '%-6s %-24s %s\n' "$1" "$2" "$(label "$3")"
    (( $3 > worst )) && worst="$3"
    return 0
}

printf '%-6s %-24s %s\n' CHECK DETAIL STATUS

mem="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d", (t - a) * 100 / t }' "${work}/meminfo")"
row memory "${mem}% used" "$(level_of mem "$mem")"

load="$(awk -v cpus=4 '{ printf "%.2f", $1 / cpus }' "${work}/loadavg")"
row load "${load} per CPU (4 CPUs)" "$(level_of load "$load")"

while read -r mount use; do
    row disk "${mount} at ${use}%" "$(level_of disk "$use")"
done < <(awk 'NR > 1 { u = $5; sub("%", "", u); print $6, u }' "${work}/df")

echo "overall: $(label "$worst")"
exit "$worst"
