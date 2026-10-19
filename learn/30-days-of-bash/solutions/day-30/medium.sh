#!/usr/bin/env bash
# Day 30 medium: threshold alerts with getopts
# Usage: medium.sh [-w WARN] [-c CRIT] [-h]
# Evaluates memory, load, and disk fixtures against thresholds.
# Exits: 0 OK, 1 WARN, 2 CRIT, 64 usage error.
set -euo pipefail

WARN=80
CRIT=90
worst=0

usage() {
    cat >&2 <<EOF
Usage: ${0##*/} [-w WARN] [-c CRIT] [-h]
  -w N   warning threshold in percent (default 80)
  -c N   critical threshold in percent (default 90)
  -h     show this help
EOF
}

is_number() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

level_of() {
    awk -v v="$1" -v w="$2" -v c="$3" 'BEGIN { print (v >= c) ? 2 : (v >= w) ? 1 : 0 }'
}

label() { case "$1" in 0) echo OK ;; 1) echo WARN ;; *) echo CRIT ;; esac; }

note() {
    (( $1 > worst )) && worst="$1"
    return 0
}

fx="$(mktemp -d)"
trap 'rm -rf -- "$fx"' EXIT

cat > "${fx}/meminfo" <<'DATA'
MemTotal: 8000000 kB
MemAvailable: 1200000 kB
DATA

cat > "${fx}/loadavg" <<'DATA'
3.50 2.10 1.00 2/300 12345
DATA

cat > "${fx}/df" <<'DATA'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 170000 30000 85% /var/lib/db
DATA

main() {
    local opt
    while getopts ":w:c:h" opt; do
        case "$opt" in
            w) WARN="$OPTARG" ;;
            c) CRIT="$OPTARG" ;;
            h) usage; return 0 ;;
            :) echo "error: -$OPTARG requires a value" >&2; usage; return 64 ;;
            *) echo "error: unknown option -$OPTARG" >&2; usage; return 64 ;;
        esac
    done

    if ! (is_number "$WARN" && is_number "$CRIT"); then
        echo "error: thresholds must be numbers" >&2
        return 64
    fi
    (( WARN < CRIT )) || { echo "error: WARN must be less than CRIT" >&2; return 64; }

    echo "CHECK  VALUE                STATUS"
    # Memory check
    local mem_pct lvl
    mem_pct="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d", (t - a) * 100 / t }' "${fx}/meminfo")"
    lvl="$(level_of "$mem_pct" "$WARN" "$CRIT")"
    printf "%-6s %-20s %s\n" "memory" "${mem_pct}% used" "$(label "$lvl")"
    note "$lvl"

    # Load check (4 CPUs -> load per CPU * 100 for threshold comparison)
    local cpus=4 load_val load_pct
    load_val="$(awk -v c="$cpus" '{ printf "%.2f", $1 / c }' "${fx}/loadavg")"
    load_pct="$(awk -v l="$load_val" 'BEGIN { printf "%d", l * 100 }')"
    lvl="$(level_of "$load_pct" "$WARN" "$CRIT")"
    printf "%-6s %-20s %s\n" "load" "${load_val} per CPU" "$(label "$lvl")"
    note "$lvl"

    # Disk check
    local mount use
    while read -r mount use; do
        lvl="$(level_of "$use" "$WARN" "$CRIT")"
        printf "%-6s %-20s %s\n" "disk" "${mount} at ${use}%" "$(label "$lvl")"
        note "$lvl"
    done < <(awk 'NR > 1 { u = $5; sub("%", "", u); print $6, u }' "${fx}/df")

    echo
    echo "overall: $(label "$worst") (exit status ${worst})"
    return "$worst"
}

main "$@"
