# Day 28: Scripting for System Administration

> **Time:** ~60 min · **Level:** Advanced
> **Prerequisites:** [Day 27](day-27.md)

## Goal

By the end of this lesson you can:

- Read CPU load, memory, disk and account information from the standard sources, safely and read-only.
- Write checks that can be tested on fixture files and that return monitoring-style exit codes.
- Combine several checks into one report whose exit status reflects the worst result.

## Concepts

### Read first, change later

A good admin script starts as a **read-only report**. Only after you trust the report do you let it
act (rotate, delete, restart), and then behind a dry-run flag and with a log. Everything in this
lesson only reads.

### Where the numbers come from

| Question | Source | Notes |
|----------|--------|-------|
| How loaded is the CPU? | `/proc/loadavg`, `uptime` | Compare the 1-minute load to `nproc` |
| How much memory is free? | `/proc/meminfo`, `free -m` | Use `MemAvailable`, not `MemFree` |
| How full are the disks? | `df -P` | `-P` = POSIX format: one line per file system |
| Who uses the space? | `du -xh --max-depth=1 /var \| sort -h` | `-x` stays on one file system |
| What is running? | `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu` | Sort and cut off with `head` |
| What is listening? | `ss -ltnp` | `-p` needs root to show other users' processes |
| Who can log in? | `getent passwd`, `/etc/passwd` | Field 3 = UID, field 7 = shell |
| Who logged in? | `last -n 10`, `who` | |
| Service state | `systemctl is-active NAME` | Only on systemd machines |
| Recent errors | `journalctl -p err -n 20 --no-pager` or `/var/log/syslog` | Often needs root or group `adm` |

> [!NOTE]
> Parse `/proc` files and `df -P`, not the pretty output of `df` or `free`, whose layout changes with
> language and version. Always use `-P` with `df`; without it a long device name wraps onto two lines.

### Testable checks: functions that accept a file

```bash
mem_used_pct() { awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%d",(t-a)*100/t}' "${1:-/proc/meminfo}"; }
```

By default the function reads the real file, but `mem_used_pct fixture.txt` lets you test with data you
control. This is the single most useful trick for admin scripts: you cannot make a real disk fill up
on demand, but you can feed the function a file that says it is full.

### Thresholds and exit codes

The monitoring convention (Nagios and many others): `0` OK, `1` WARNING, `2` CRITICAL, `3` UNKNOWN. A
combined check exits with the **worst** result so cron, CI and monitoring systems can act on it.

### Privilege

Run as a normal user whenever possible. If part of a script needs root, say so in its header, check
`(( EUID == 0 ))` early, and print a clear message instead of failing later with a confusing
"permission denied". Never run a whole script as root just to read `df`.

## Worked example

The functions below read `/proc` and `df -P` by default; here they run on fixtures, so the output is
repeatable. The last three lines run them for real and only check the *shape* of the answer. Save as
`sysadmin.sh`.

```bash
#!/usr/bin/env bash
# sysadmin.sh - read-only health checks. Each function reads a REAL source by default
# (/proc/meminfo, /proc/loadavg, df -P) but accepts a file, so we can test with fixtures.
set -euo pipefail

mem_used_pct() {                      # percent of memory in use: (total - available) / total
    awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 }
         END { printf "%d", (t - a) * 100 / t }' "${1:-/proc/meminfo}"
}

load_per_cpu() {                      # 1-minute load average divided by the number of CPUs
    awk -v cpus="${CPUS:-$(nproc)}" '{ printf "%.2f", $1 / cpus }' "${1:-/proc/loadavg}"
}

disk_over() {                         # disk_over THRESHOLD [df-output-file] : mounts at or above it
    local threshold="$1"
    shift
    { if (( $# > 0 )); then cat "$1"; else df -P; fi; } |
        awk -v th="$threshold" 'NR > 1 { use = $5; sub("%", "", use)
                                          if (use + 0 >= th) printf "%s %s%%\n", $6, use }'
}

severity() {                          # severity VALUE WARN CRIT : prints OK, WARN or CRIT
    awk -v v="$1" -v w="$2" -v c="$3" 'BEGIN { print (v >= c) ? "CRIT" : (v >= w) ? "WARN" : "OK" }'
}

# ---- fixtures: same format as the real files ---------------------------------------------
cat > meminfo.fix <<'EOF'
MemTotal:        8000000 kB
MemFree:          500000 kB
MemAvailable:    1200000 kB
SwapTotal:       2000000 kB
SwapFree:        1900000 kB
EOF
echo '3.50 2.10 1.00 2/300 12345' > loadavg.fix
cat > df.fix <<'EOF'
Filesystem     1024-blocks     Used Available Capacity Mounted on
/dev/sda1           100000    93000      7000      93% /
/dev/sdb1           500000   100000    400000      20% /data
/dev/sdc1           200000   170000     30000      85% /var/lib/db
tmpfs                 8000        0      8000       0% /run
EOF

echo "--- memory"
mem="$(mem_used_pct meminfo.fix)"
echo "used: ${mem}%  -> $(severity "$mem" 80 90)"

echo "--- load (4 CPUs)"
load="$(CPUS=4 load_per_cpu loadavg.fix)"
echo "load per CPU: ${load}  -> $(severity "$load" 0.7 1.0)"

echo "--- disks at or above 80%"
disk_over 80 df.fix

echo "--- the same functions work on this machine (output varies, so only the shape is shown)"
[[ $(mem_used_pct) =~ ^[0-9]+$ ]] && echo "mem_used_pct reads /proc/meminfo: ok"
[[ $(load_per_cpu) =~ ^[0-9]+\.[0-9]{2}$ ]] && echo "load_per_cpu reads /proc/loadavg: ok"
disk_over 101 >/dev/null && echo "disk_over runs df -P: ok"
```

**Expected output**

```text
--- memory
used: 85%  -> WARN
--- load (4 CPUs)
load per CPU: 0.88  -> WARN
--- disks at or above 80%
/ 93%
/var/lib/db 85%
--- the same functions work on this machine (output varies, so only the shape is shown)
mem_used_pct reads /proc/meminfo: ok
load_per_cpu reads /proc/loadavg: ok
disk_over runs df -P: ok
```

`severity` is a tiny reusable helper that uses `awk` for the comparison, because Bash arithmetic cannot
compare decimals like `0.88`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `awk '{print $5}'` over `df` output | Includes the header (`Use%`) | `NR > 1` |
| `[[ $use > 90 ]]` with `93%` | `>` compares strings, and `%` is still there | Strip `%`, compare with `(( ))` |
| `df` without `-P` | Long device names wrap onto two lines, breaking columns | `df -P` |
| Using `MemFree` as "free memory" | Ignores reclaimable cache; looks falsely alarming | `MemAvailable` |
| Comparing the load average with a fixed number | A load of 4 is fine on 16 CPUs and terrible on 1 | Divide by `nproc` |
| Parsing `ps aux` with `cut -d' '` | Columns are space-padded | `ps -eo` with chosen columns, or `awk` |
| Running every check as root | A bug has full power | Least privilege; root only where needed |
| Alert fatigue from checks that always say WARN | People ignore them | Tune thresholds; test with fixtures |

## Exercises

### Easy: memory report with severity

Write `mem_report [FILE]` that reads `MemTotal` and `MemAvailable` (default `/proc/meminfo`), prints
`memory: X MB used of Y MB (P%) LEVEL` with levels `OK` below 80, `WARN` from 80, `CRIT` from 90, and
returns 0, 1 or 2. Test it on three fixture files with 20%, 95% and 85% usage.

**Acceptance criteria**

- Output levels `OK`, `CRIT`, `WARN` and return codes 0, 2, 1 respectively.
- Percentages use integer arithmetic.
- Defaults to the real `/proc/meminfo` when called without a file.

### Medium: account audit

Given fixture `passwd` and `shadow` files, list the human accounts (UID 1000 or more with a login shell
that is not `nologin` or `false`), report any extra account with UID 0 besides `root`, and list the
accounts with an empty password field in `shadow`.

**Acceptance criteria**

- Humans: `ada` and `grace`; `svc-app` (shell `/bin/false`) is excluded.
- Extra UID 0: `toor`, with a `WARNING` line.
- Empty password: `grace`.
- Read-only: nothing under `/etc` is touched.

### Hard: combined health check

Using fixtures (memory 85%, load 3.5 on 4 CPUs, three file systems at 93%, 20% and 85%), print a table
with `CHECK`, `DETAIL` and `STATUS`, one row for memory, one for load and one per file system. Keep the
warn/crit thresholds in associative arrays. The script's exit status is the worst level seen.

**Acceptance criteria**

- Rows: memory WARN, load WARN, `/` CRIT, `/data` OK, `/var/lib/db` WARN.
- Last line `overall: CRIT` and exit status 2.
- Changing a fixture value changes the table with no code changes.

### Break it

This script should alert only on the file system above 90%. It has **two bugs**; save as
`break-it.sh`, run it, and fix it so the only alert is for `/`.

```bash
#!/usr/bin/env bash
cat > df.txt <<'EOF'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/sda1 100000 93000 7000 93% /
/dev/sdb1 500000 100000 400000 20% /data
/dev/sdc1 200000 150000 50000 75% /var
EOF

for use in $(awk '{ print $5 }' df.txt); do
    if [[ $use > 90% ]]; then
        echo "ALERT: $use"
    fi
done
```

**Expected output**

```text
ALERT: Capacity
ALERT: 93%
```

<details>
<summary>Hint</summary>

What word does the first line of `df` output contain in column five? And what kind of comparison is
`>` inside `[[ ]]`?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 28 easy: memory report with a severity level, tested on a fixture file.
# Read-only. Pass a file to use it instead of /proc/meminfo.
set -euo pipefail

mem_report() {
    local file="${1:-/proc/meminfo}" warn=80 crit=90 total avail used pct level
    total="$(awk '/^MemTotal:/ { print $2 }' "$file")"
    avail="$(awk '/^MemAvailable:/ { print $2 }' "$file")"
    used=$(( total - avail ))
    pct=$(( used * 100 / total ))
    if (( pct >= crit )); then level=CRIT
    elif (( pct >= warn )); then level=WARN
    else level=OK
    fi
    printf 'memory: %d MB used of %d MB (%d%%) %s\n' $(( used / 1024 )) $(( total / 1024 )) "$pct" "$level"
    case "$level" in OK) return 0 ;; WARN) return 1 ;; *) return 2 ;; esac
}

work="$(mktemp -d)"
for pair in "8000000 6400000" "8000000 400000" "8000000 1200000"; do
    read -r total avail <<< "$pair"
    printf 'MemTotal: %d kB\nMemAvailable: %d kB\n' "$total" "$avail" > "${work}/meminfo"
    status=0
    mem_report "${work}/meminfo" || status=$?
    echo "  exit status ${status}"
done
rm -rf -- "$work"
```

**Expected output**

```text
memory: 1562 MB used of 7812 MB (20%) OK
  exit status 0
memory: 7421 MB used of 7812 MB (95%) CRIT
  exit status 2
memory: 6640 MB used of 7812 MB (85%) WARN
  exit status 1
```

</details>

<details>
<summary>Medium</summary>

`awk -F:` splits on colons; the condition `$7 !~ /(nologin|false)$/` is a regex that must **not** match.
Numeric comparison (`$3 >= 1000`) works because awk treats the field as a number.

```bash
#!/usr/bin/env bash
# Day 28 medium: audit user accounts from passwd/shadow-format files (fixtures, read-only).
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
ada:x:1000:1000:Ada:/home/ada:/bin/bash
grace:x:1001:1001:Grace:/home/grace:/bin/zsh
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
toor:x:0:0:second root:/root:/bin/sh
svc-app:x:1002:1002:app:/srv/app:/bin/false
EOF
cat > "${work}/shadow" <<'EOF'
root:$6$hash:19000:0:99999:7:::
ada:$6$hash:19000:0:99999:7:::
grace::19000:0:99999:7:::
svc-app:!:19000:0:99999:7:::
EOF

echo "human accounts (UID >= 1000 with a real login shell):"
awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)$/ { printf "  %-8s uid=%s shell=%s\n", $1, $3, $7 }' "${work}/passwd"

echo "accounts with UID 0 (should be only root):"
awk -F: '$3 == 0 { print "  " $1 }' "${work}/passwd"
extra="$(awk -F: '$3 == 0 && $1 != "root" { n++ } END { print n + 0 }' "${work}/passwd")"
(( extra == 0 )) || echo "WARNING: ${extra} extra UID 0 account(s)"

echo "accounts with an EMPTY password field in shadow:"
awk -F: '$2 == "" { print "  " $1 }' "${work}/shadow"

rm -rf -- "$work"
```

**Expected output**

```text
human accounts (UID >= 1000 with a real login shell):
  ada      uid=1000 shell=/bin/bash
  grace    uid=1001 shell=/bin/zsh
accounts with UID 0 (should be only root):
  root
  toor
WARNING: 1 extra UID 0 account(s)
accounts with an EMPTY password field in shadow:
  grace
```

</details>

<details>
<summary>Hard</summary>

`level_of` returns a number so levels can be compared with `>`; `label` turns it back into text. The
`row` function updates `worst`. Because the `while` loop reads from process substitution it runs in the
current shell, so `worst` survives.

```bash
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
```

**Expected output**

```text
CHECK  DETAIL                   STATUS
memory 85% used                 WARN
load   0.88 per CPU (4 CPUs)    WARN
disk   / at 93%                 CRIT
disk   /data at 20%             OK
disk   /var/lib/db at 85%       WARN
overall: CRIT
```

</details>

<details>
<summary>Break it</summary>

Bug 1: the header line was included, so `Capacity` was tested. Bug 2: `[[ $use > 90% ]]` compares
**strings**, so `93%` > `90%` worked by luck and the header's `C` sorted above `9`. Skip line 1, strip the
`%`, and use `(( use > 90 ))`. Also read lines, not words, with `while read`.

```bash
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
```

**Expected output**

```text
ALERT: / is at 93%
```

</details>

Solution files live in [`solutions/day-28/`](solutions/day-28/).

## Self-check

1. Why use `df -P` in scripts?
2. Which `/proc/meminfo` field shows memory that applications can really use?
3. Why divide the load average by the number of CPUs?
4. What do exit codes 0, 1, 2 mean in the monitoring convention?
5. Why make check functions accept an optional input file?

<details>
<summary>Answers</summary>

1. POSIX output keeps each file system on one line, so columns are predictable.
2. `MemAvailable`.
3. A load of 4 means something different on 1 CPU and on 16 CPUs.
4. OK, WARNING, CRITICAL.
5. So you can test the logic with fixtures that simulate full disks, high load and so on.

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `df -P` | File system usage, one line each |
| `du -xh --max-depth=1 DIR \| sort -h` | Biggest subdirectories |
| `awk '/^MemAvailable:/ {print $2}' /proc/meminfo` | Available memory (kB) |
| `cut -d' ' -f1 /proc/loadavg`, `nproc` | 1-minute load, CPU count |
| `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu \| head` | Top CPU users |
| `ss -ltn` | Listening ports |
| `getent passwd` | All accounts |
| `last -n 10` | Recent logins |
| `systemctl is-active NAME` | Service state |
| `exit 0/1/2/3` | OK / WARN / CRIT / UNKNOWN |

## Further reading

- [proc(5) manual](https://man7.org/linux/man-pages/man5/proc.5.html): what every file under `/proc`
  contains, including `meminfo` and `loadavg`.
- [Monitoring Plugins development guidelines](https://www.monitoring-plugins.org/doc/guidelines.html):
  the origin of the 0/1/2/3 exit code convention.
- [passwd(5) manual](https://man7.org/linux/man-pages/man5/passwd.5.html): the fields of
  `/etc/passwd`.

**Next:** [Day 29](day-29.md)
