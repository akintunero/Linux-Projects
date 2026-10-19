#!/usr/bin/env bash
# Day 30 capstone: sysdash - a read-only system administration dashboard.
#
# Usage:  hard.sh [-w WARN] [-c CRIT] [-o REPORT_FILE] [-h]
# Data:   demo fixtures by default (repeatable output); LIVE=1 reads this machine instead.
# Exit:   0 all OK, 1 something at WARN, 2 something CRIT, 64 bad usage.
# Safety: read-only. Writes only the optional report file and a private temp directory.
set -euo pipefail

WARN=80
CRIT=90
worst=0
report_file=""
fx="$(mktemp -d)"
trap 'rm -rf -- "$fx"' EXIT

usage() {
    cat >&2 <<EOF
Usage: ${0##*/} [-w WARN] [-c CRIT] [-o REPORT_FILE] [-h]
  -w N   warning threshold in percent (default 80)
  -c N   critical threshold in percent (default 90)
  -o F   also write the report to file F
  -h     this help      (set LIVE=1 to read this machine instead of demo data)
EOF
}

is_number() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# ---- data sources ----------------------------------------------------------------------
make_fixtures() {
    printf 'MemTotal: 8000000 kB\nMemAvailable: 1200000 kB\n' > "${fx}/meminfo"
    echo '3.50 2.10 1.00 2/300 12345' > "${fx}/loadavg"
    echo '93784.12 360000.00' > "${fx}/uptime"
    cat > "${fx}/df" <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 170000 30000 85% /var/lib/db
EOF
    cat > "${fx}/ps" <<'EOF'
  PID USER         %CPU %MEM COMMAND
 1201 postgres     45.2  8.1 postgres
  877 www-data     12.5  2.2 nginx
  310 root          1.0  0.4 sshd
 5521 ada           0.3  0.1 bash
EOF
    printf '%s\n' sshd nginx > "${fx}/running"
    cat > "${fx}/app.log" <<'EOF'
2025-10-10 13:00:01 INFO  started
2025-10-10 13:05:12 ERROR database timeout
2025-10-10 13:06:40 WARN  slow query
2025-10-10 13:09:55 ERROR disk write failed
EOF
}

if [[ ${LIVE:-0} == 1 ]]; then
    CPUS="$(nproc)"
    meminfo=/proc/meminfo; loadavg=/proc/loadavg; uptime_file=/proc/uptime
    df_cmd() { df -P; }
    ps_cmd() { ps -eo pid,user:12,pcpu,pmem,comm --sort=-pcpu | head -n 4; }
    service_running() { pgrep -x "$1" >/dev/null 2>&1; }
    log_file=""
    services=(sshd cron)
else
    make_fixtures
    CPUS=4
    meminfo="${fx}/meminfo"; loadavg="${fx}/loadavg"; uptime_file="${fx}/uptime"
    df_cmd() { cat "${fx}/df"; }
    ps_cmd() { head -n 4 "${fx}/ps"; }
    service_running() { grep -qx "$1" "${fx}/running"; }
    log_file="${fx}/app.log"
    services=(sshd nginx postgres)
fi

# ---- helpers ---------------------------------------------------------------------------
level_of() {                                  # level_of VALUE WARN CRIT -> 0 OK, 1 WARN, 2 CRIT
    awk -v v="$1" -v w="$2" -v c="$3" 'BEGIN { print (v >= c) ? 2 : (v >= w) ? 1 : 0 }'
}
label() { case "$1" in 0) echo OK ;; 1) echo WARN ;; *) echo CRIT ;; esac; }
note() {                                      # note LEVEL : remember the worst level seen
    (( $1 > worst )) && worst="$1"
    return 0
}
section() { printf '\n== %s ==\n' "$1"; }
line() {                                      # line LABEL VALUE [LEVEL]
    if [[ -n ${3:-} ]]; then
        printf '%-10s %-28s %s\n' "$1" "$2" "$(label "$3")"
        note "$3"
    else
        printf '%-10s %s\n' "$1" "$2"
    fi
}

# ---- the dashboard ---------------------------------------------------------------------
render() {
    local secs mem load l mount use svc errors

    echo "SYSDASH report ($([[ ${LIVE:-0} == 1 ]] && echo live || echo demo) data)"

    section SYSTEM
    line kernel "$(uname -s)"
    secs="$(cut -d. -f1 "$uptime_file")"
    line uptime "$(( secs / 86400 ))d $(( secs % 86400 / 3600 ))h $(( secs % 3600 / 60 ))m"

    section RESOURCES
    mem="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d", (t - a) * 100 / t }' "$meminfo")"
    line memory "${mem}% used" "$(level_of "$mem" "$WARN" "$CRIT")"
    load="$(awk -v cpus="$CPUS" '{ printf "%.2f", $1 / cpus }' "$loadavg")"
    line load "${load} per CPU (${CPUS} CPUs)" "$(level_of "$(awk -v l="$load" 'BEGIN { print l * 100 }')" "$WARN" "$CRIT")"

    section DISKS
    while read -r mount use; do
        line disk "${mount} at ${use}%" "$(level_of "$use" "$WARN" "$CRIT")"
    done < <(df_cmd | awk 'NR > 1 { u = $5; sub("%", "", u); print $6, u }')

    section "TOP PROCESSES (by CPU)"
    ps_cmd

    section SERVICES
    for svc in "${services[@]}"; do
        if service_running "$svc"; then l=0; else l=2; fi
        line service "$svc" "$l"
    done

    section "LOG ERRORS"
    if [[ -n $log_file ]]; then
        errors="$(grep -c ' ERROR ' "$log_file" || true)"
        line errors "${errors} in app.log" "$(( errors > 0 ? 1 : 0 ))"
        grep ' ERROR ' "$log_file" | tail -n 2 | sed 's/^/    /' || true
    else
        line errors "no log file configured"
    fi

    echo
    echo "overall: $(label "$worst") (exit status ${worst})"
}

main() {
    local opt
    while getopts ":w:c:o:h" opt; do
        case "$opt" in
            w) WARN="$OPTARG" ;;
            c) CRIT="$OPTARG" ;;
            o) report_file="$OPTARG" ;;
            h) usage; return 0 ;;
            :) echo "error: -$OPTARG needs a value" >&2; usage; return 64 ;;
            *) echo "error: unknown option -$OPTARG" >&2; usage; return 64 ;;
        esac
    done
    if ! (is_number "$WARN" && is_number "$CRIT"); then
        echo "error: thresholds must be numbers" >&2
        return 64
    fi
    (( WARN < CRIT )) || { echo "error: WARN must be below CRIT" >&2; return 64; }

    render > "${fx}/report.txt"                # runs in this shell, so $worst survives
    cat "${fx}/report.txt"
    [[ -z $report_file ]] || cp -- "${fx}/report.txt" "$report_file"
    return "$worst"
}

main "$@"
