# Day 30: Capstone Project: System-Admin Dashboard

> **Time:** ~90 min · **Level:** Advanced
> **Prerequisites:** [Day 01](day-01.md) through [Day 29](day-29.md)

## Goal

Bring together everything you have learned across the 30 days into a single production-grade,
read-only system administration dashboard script (`sysdash`):

- Structure an unattended command-line utility with robust argument parsing via `getopts`.
- Gather live metrics (uptime, memory, CPU load, disk usage, active services, error logs) safely.
- Support both live production inspection and repeatable fixture datasets for automated testing.
- Return standard monitoring exit codes (0 = OK, 1 = WARN, 2 = CRIT, 64 = usage error).
- Evaluate your work against a 100-point professional grading rubric.

## Concepts

### The Capstone Architecture

A dependable system administration tool follows four core engineering principles:

1. **Safety First (Read-Only):** The tool inspects state without modifying system settings or
   risking service interruption. Any temporary files are isolated in a private directory and cleaned
   up on exit with `trap`.
2. **Deterministic Testability:** A flag or environment variable switches between real system sources
   (`/proc`, `df`, `ps`, `systemctl`) and controlled test fixtures. This allows automated test
   suites to assert behavior across edge cases (e.g., 100% disk capacity, decimal load spikes).
3. **Standardized Severity & Exit Status:** Multi-component health checks must roll up to a single
   definitive process exit code representing the worst condition found:
   - `0`: All systems OK.
   - `1`: At least one check triggered a WARNING threshold.
   - `2`: At least one check triggered a CRITICAL threshold.
   - `64`: Command-line usage error (invalid flags or malformed threshold parameters).
4. **Resilient Data Parsing:** Never assume standard `df` or `free` formatting. Use `df -P` to
   prevent filesystem names from wrapping, parse `/proc/meminfo` using `MemAvailable` instead of
   `MemFree`, and use tools like `awk` for floating-point calculations that Bash arithmetic cannot handle.

### Severity Rollup Pattern

Track the worst severity seen across any check using a monotonic helper function:

```bash
worst=0
note() {
    (( $1 > worst )) && worst="$1"
    return 0
}

# In each check:
lvl="$(level_of "$mem_pct" "$WARN" "$CRIT")"
note "$lvl"
```

## Worked example

The following example shows how to inspect uptime, memory, CPU load, and disk capacity, formatting
them cleanly while handling non-integer load values.

```bash
#!/usr/bin/env bash
# capstone.sh - a compact read-only system summary demonstrating how pieces combine.
set -euo pipefail

fx="$(mktemp -d)"
trap 'rm -rf -- "$fx"' EXIT

cat > "${fx}/uptime" <<'DATA'
93784.12 360000.00
DATA
cat > "${fx}/meminfo" <<'DATA'
MemTotal: 8000000 kB
MemAvailable: 1200000 kB
DATA
echo '3.50 2.10 1.00 2/300 12345' > "${fx}/loadavg"
cat > "${fx}/df" <<'DATA'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 170000 30000 85% /var/lib/db
DATA

# 1. Format uptime into human-readable components
secs="$(cut -d. -f1 "${fx}/uptime")"
days=$(( secs / 86400 ))
hours=$(( secs % 86400 / 3600 ))
mins=$(( secs % 3600 / 60 ))
printf "Uptime:   %dd %dh %dm\n" "$days" "$hours" "$mins"

# 2. Memory calculation safely via awk
mem_pct="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d", (t - a) * 100 / t }' "${fx}/meminfo")"
printf "Memory:   %s%% used\n" "$mem_pct"

# 3. CPU Load per core
cpus=4
load_core="$(awk -v c="$cpus" '{ printf "%.2f", $1 / c }' "${fx}/loadavg")"
printf "Load:     %s per core (%s cores)\n" "$load_core" "$cpus"

# 4. Filter disks using POSIX format
echo "Disks (mounts >= 80%):"
while read -r mount use; do
    printf "  %-12s %s\n" "$mount" "${use}%"
done < <(awk 'NR > 1 { u = $5; sub("%", "", u); if (u + 0 >= 80) print $6, u }' "${fx}/df")
```

**Expected output**

```text
Uptime:   1d 2h 3m
Memory:   85% used
Load:     0.88 per core (4 cores)
Disks (mounts >= 80%):
  /            93%
  /var/lib/db  85%
```

## Common mistakes

| Mistake | What happens | Correct approach |
|---------|--------------|------------------|
| String comparison on percentage (`[[ "100%" > "90%" ]]`) | Evaluates to `false` because `'1'` comes before `'9'` in ASCII table | Strip `%` with `sub("%", "", u)` and compare numerically with `(( ... ))` |
| Floating point arithmetic in `(( load > 1.5 ))` | Bash throws a syntax error on decimal points | Use `awk` or `bc` to compare floating point numbers |
| Hardcoding live paths during tests | Unit tests fail in non-root or containerized environments | Parameterize data sources so fixtures can be injected |
| Swallowing pipeline exit codes | Silent failures hide corrupted monitoring output | Use `set -euo pipefail` and test pipeline stages |
| Exiting 0 on critical warnings | Monitoring systems (Nagios, Zabbix, Datadog) report false greens | Track worst severity encountered and return it as the script exit code |

## Exercises

### Easy: Fixture-based Mini Dashboard

Write a script that reads simulated `uptime`, `/proc/meminfo`, and `/proc/loadavg` fixture files and formats them into a clean 3-line terminal report.

- **Acceptance criteria:**
  - Formats raw uptime seconds into `"Xd Xh Xm"`.
  - Calculates memory used percentage from `MemTotal` and `MemAvailable`.
  - Displays 1-minute, 5-minute, and 15-minute load averages.
  - Exits with status 0.

### Medium: Threshold Alerts with `getopts`

Extend the dashboard to parse `-w` (warning threshold) and `-c` (critical threshold) arguments using `getopts`.

- **Acceptance criteria:**
  - Defaults to `-w 80` and `-c 90`.
  - Validates that `-w` and `-c` are numbers and that warning is strictly less than critical.
  - Returns exit code 64 on invalid usage.
  - Checks memory, load per core, and disk usage against thresholds.
  - Returns exit code 0 if all OK, 1 if any WARN, and 2 if any CRIT.

### Hard: Complete Production Dashboard (`sysdash`)

Implement a comprehensive, modular system administration dashboard with report output support.

- **Acceptance criteria:**
  - Supports `-w WARN`, `-c CRIT`, `-o REPORT_FILE`, and `-h`.
  - Uses demo fixtures by default, but inspects live system metrics when `LIVE=1`.
  - Reports system kernel, uptime, memory, CPU load per core, all mounted disks, top CPU processes, service health, and recent application log error counts.
  - Uses `trap` to guarantee temp directory cleanup.
  - Passes `shellcheck -x` with zero warnings.

## Break it

The following script attempts to evaluate disk usage and load averages, but contains three subtle
production bugs:

```bash
#!/usr/bin/env bash
# break-it.sh: demonstrate common sysadmin script bugs
# Bug 1: string comparison of "100%" with numbers ("100%" < "90%")
# Bug 2: (( )) arithmetic evaluation on decimal load average
# Bug 3: script always exits 0 even when critical alerts fired

cat > df.txt <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 100000 0 100% /
/dev/sdb1 500000 100000 400000 20% /data
EOF

echo '1.85 0.90 0.50' > load.txt

# Bug 1: string comparison
use="$(awk 'NR==2 { print $5 }' df.txt)"
if [[ $use > 90% ]]; then
    echo "ALERT: disk $use"
else
    echo "MISSED: disk is $use but string test '$use > 90%' evaluated false!"
fi

# Bug 2: (( )) with decimal load
load="$(cut -d' ' -f1 load.txt)"
echo "Testing load: $load"
if (( load > 1 )); then
    echo "ALERT: load $load"
fi

# Bug 3: unconditional exit 0
exit 0
```

**Expected output**

```bash
#!/usr/bin/env bash
# break-it.sh: demonstrate common sysadmin script bugs
# Bug 1: string comparison of "100%" with numbers ("100%" < "90%")
# Bug 2: (( )) arithmetic evaluation on decimal load average
# Bug 3: script always exits 0 even when critical alerts fired

cat > df.txt <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 100000 0 100% /
/dev/sdb1 500000 100000 400000 20% /data
EOF

echo '1.85 0.90 0.50' > load.txt

# Bug 1: string comparison
use="$(awk 'NR==2 { print $5 }' df.txt)"
if [[ $use > 90% ]]; then
    echo "ALERT: disk $use"
else
    echo "MISSED: disk is $use but string test '$use > 90%' evaluated false!"
fi

# Bug 2: (( )) with decimal load
load="$(cut -d' ' -f1 load.txt)"
echo "Testing load: $load"
if (( load > 1 )); then
    echo "ALERT: load $load"
fi

# Bug 3: unconditional exit 0
exit 0
```

**Expected output**

```text
MISSED: disk is 100% but string test '100% > 90%' evaluated false!
Testing load: 1.85
break-it.sh: line 26: ((: 1.85: arithmetic syntax error: invalid arithmetic operator (error token is ".85")
```

## Solutions

<details>
<summary>Solutions</summary>

### Easy

```bash
#!/usr/bin/env bash
# Day 30 easy: fixture-based mini dashboard
# Reads uptime, meminfo, and loadavg fixtures and formats them.
set -euo pipefail

fx="$(mktemp -d)"
trap 'rm -rf -- "$fx"' EXIT

cat > "${fx}/uptime" <<'DATA'
93784.12 360000.00
DATA

cat > "${fx}/meminfo" <<'DATA'
MemTotal: 8000000 kB
MemAvailable: 1200000 kB
DATA

cat > "${fx}/loadavg" <<'DATA'
3.50 2.10 1.00 2/300 12345
DATA

# Format uptime as "1d 2h 3m"
secs="$(cut -d. -f1 "${fx}/uptime")"
days=$(( secs / 86400 ))
hours=$(( secs % 86400 / 3600 ))
mins=$(( secs % 3600 / 60 ))
uptime_fmt="${days}d ${hours}h ${mins}m"

# Memory used percent
mem_used="$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } END { printf "%d%%", (t - a) * 100 / t }' "${fx}/meminfo")"

# Load averages (1m, 5m, 15m)
read -r load1 load5 load15 _ < "${fx}/loadavg"

printf "UPTIME: %s\n" "$uptime_fmt"
printf "MEMORY: %s used\n" "$mem_used"
printf "LOAD:   %s (1m), %s (5m), %s (15m)\n" "$load1" "$load5" "$load15"
```

**Expected output**

```text
UPTIME: 1d 2h 3m
MEMORY: 85% used
LOAD:   3.50 (1m), 2.10 (5m), 1.00 (15m)
```

### Medium

```bash
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
```

**Expected output**

```text
CHECK  VALUE                STATUS
memory 85% used             WARN
load   0.88 per CPU         WARN
disk   / at 93%             CRIT
disk   /data at 20%         OK
disk   /var/lib/db at 85%   WARN

overall: CRIT (exit status 2)
```

### Hard

```bash
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
```

**Expected output**

```text
SYSDASH report (demo data)

== SYSTEM ==
kernel     Linux
uptime     1d 2h 3m

== RESOURCES ==
memory     85% used                     WARN
load       0.88 per CPU (4 CPUs)        WARN

== DISKS ==
disk       / at 93%                     CRIT
disk       /data at 20%                 OK
disk       /var/lib/db at 85%           WARN

== TOP PROCESSES (by CPU) ==
  PID USER         %CPU %MEM COMMAND
 1201 postgres     45.2  8.1 postgres
  877 www-data     12.5  2.2 nginx
  310 root          1.0  0.4 sshd

== SERVICES ==
service    sshd                         OK
service    nginx                        OK
service    postgres                     CRIT

== LOG ERRORS ==
errors     2 in app.log                 WARN
    2025-10-10 13:05:12 ERROR database timeout
    2025-10-10 13:09:55 ERROR disk write failed

overall: CRIT (exit status 2)
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `[[ $use > 90% ]]` performed a lexicographical string comparison where `"100%"` sorted before `"90%"`.
Bug 2: Bash `(( ... ))` cannot parse decimal floats such as `1.85`.
Bug 3: The script ended with an unconditional `exit 0`, masking the alert state.

```bash
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
```

**Expected output**

```text
ALERT: disk is 100% (critical)
ALERT: load is 1.85 (warning)
overall status: exit 2
```

</details>

Solution files live in [`solutions/day-30/`](solutions/day-30/).

## Grading Rubric (100 Points)

Use this rubric to evaluate your capstone project implementation or peer submissions:

| Criterion | Points | Excellent (Full Points) | Satisfactory (Half Points) | Needs Improvement (0-2 Points) |
|-----------|--------|-------------------------|----------------------------|--------------------------------|
| **1. Correctness & Accuracy** | 20 | All metrics (uptime, memory %, load/core, disk %, services, log errors) accurately calculated and formatted. | 1-2 calculations inaccurate or formatting broken under edge cases. | Major calculation errors; metrics missing or misleading. |
| **2. Safety & Read-Only Operation** | 15 | Strictly non-destructive. Clean trap handling removes temporary files even on `SIGINT`/`SIGTERM`. | Creates temporary files without reliable cleanup traps. | Modifies system files or services without explicit authorization. |
| **3. Error Handling & Exit Codes** | 20 | Conforms strictly to monitoring standards: 0 (OK), 1 (WARN), 2 (CRIT), 64 (usage). Worst-status rollup works correctly. | Inconsistent exit codes; usage errors do not exit 64. | Always exits 0 or crashes unhandled with ambiguous errors. |
| **4. Code Quality & ShellCheck** | 15 | Passes `shellcheck -x` cleanly with no suppressions (or justified comments). Strict mode (`set -euo pipefail`) used. Variables quoted. | Minor shellcheck warnings or unquoted variables. | Fails strict mode; multiple unquoted variables; poor scoping. |
| **5. Testability & Fixtures** | 15 | Decoupled architecture allowing full test execution via fixtures without root or live system dependencies. | Supports fixtures but hardcodes specific machine assumptions. | No fixture support; can only run against a live system. |
| **6. Usability & Documentation** | 15 | Comprehensive `-h` help message, clear output formatting with aligned columns, optional file logging with `-o`. | Help message sparse or output difficult to read on standard terminals. | No help message; flags undocumented; confusing output. |

## Self-check

1. Why must disk usage comparison strip the trailing `%` character before comparing?
2. What exit code should be returned if one check reports `WARN` and another reports `CRIT`?
3. How can a script support automated unit testing when inspecting `/proc` or `ps`?
4. Why should `df -P` always be used instead of plain `df` in administrative scripts?
5. What signal traps are most critical for cleaning up dashboard temporary files?

<details>
<summary>Answers</summary>

1. If compared as strings, `"100%"` evaluates as less than `"90%"` because `'1'` is ASCII 49 and `'9'` is ASCII 57.
2. Exit code 2 (`CRIT`), as administrative reporting tools must report the worst severity observed.
3. Provide fixture data sources by default or via parameter/environment injection so tests run reproducibly.
4. The `-P` flag enforces POSIX output format, guaranteeing each filesystem entry stays on one line regardless of name length.
5. `trap 'rm -rf -- "$fx"' EXIT` handles clean exit, errors (`set -e`), and interruption signals (`SIGINT`, `SIGTERM`).

</details>

## Cheat sheet

| Feature | Pattern | Notes |
|---------|---------|-------|
| Strict Mode | `set -euo pipefail` | Fail early on errors and unset variables |
| Trap Cleanup | `trap 'rm -rf -- "$fx"' EXIT` | Fires on standard exit or errors |
| Usage Options | `while getopts ":w:c:o:h" opt; do ...` | Leading `:` enables custom error handling |
| Exit Codes | `0=OK, 1=WARN, 2=CRIT, 64=USAGE` | Sysexits standard for command-line tools |
| Mem Calculation | `awk '/^MemTotal:/... END { printf "%d", (t-a)*100/t }'` | Always use `MemAvailable` |
| Monotonic Severity | `(( $1 > worst )) && worst="$1"` | Rollup highest severity |

## Further reading

- [Greg's Wiki: BashPitfalls](https://mywiki.wooledge.org/BashPitfalls):
  common pitfalls in conditional evaluations and string comparisons.
- [POSIX Utility Conventions: getopts](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/getopts.html):
  standard argument parsing conventions in shell scripting.
- [FreeBSD Sysexits Man Page](https://man.freebsd.org/cgi/man.cgi?query=sysexits):
  standard error and exit codes for CLI utilities.

**Next:** [Course Syllabus and Overview](README.md)
