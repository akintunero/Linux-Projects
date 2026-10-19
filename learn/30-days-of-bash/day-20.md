# Day 20: Scheduling with `cron`

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 19](day-19.md)

## Goal

By the end of this lesson you can:

- Read and write crontab schedules (`*/15 9-17 * * 1-5`) and explain each field.
- Write a script that behaves the same under cron's bare environment as in your terminal.
- Prevent overlapping runs with `flock` and capture output in a log.

## Concepts

### What cron does

`cron` is a daemon that starts commands on a schedule. Each user has a **crontab** (a table of
schedules). You edit yours with `crontab -e`, list it with `crontab -l`.

```text
# m  h  dom mon dow  command
  30 2  *   *   *    /home/ada/bin/backup.sh >> /home/ada/backup.log 2>&1
```

| Field | Values |
|-------|--------|
| minute | 0-59 |
| hour | 0-23 |
| day of month | 1-31 |
| month | 1-12 |
| day of week | 0-7 (0 and 7 are Sunday) |

Syntax in a field: `*` every value, `5,10` a list, `9-17` a range, `*/15` every 15th, `0-30/10` a
stepped range. If both day-of-month and day-of-week are restricted, the job runs when **either**
matches. Shortcuts: `@reboot`, `@hourly`, `@daily`, `@weekly`, `@monthly`.

> [!WARNING]
> `crontab -r` deletes your **entire** crontab immediately, with no confirmation. It sits right next
> to `-e` on the keyboard. Back up first: `crontab -l > crontab.backup`. In this lesson we never touch
> your real crontab: schedules go to a file and jobs are tested by running them by hand.

### Cron's environment is not your environment

| In your terminal | Under cron |
|------------------|------------|
| Long `PATH` from `.bashrc` | Minimal: `/usr/bin:/bin` |
| Working directory: where you are | Your home directory |
| Aliases, functions, your variables | None |
| Output appears on screen | Emailed (if mail is set up) or discarded |
| Time zone: yours | The system's (often UTC) |

So a cron-ready script: sets its own `PATH`, uses **absolute paths** (or `cd` to its own directory),
and sends output to a log with `>> file 2>&1`.

### Test like cron

```bash
cd / && env -i HOME="$HOME" PATH=/usr/bin:/bin bash /full/path/job.sh
```

`env -i` empties the environment. If the job works there, it will work under cron.

### No overlap: `flock`

If a run takes longer than the interval, runs pile up. A lock stops that:

```bash
exec 9> /tmp/job.lock
flock -n 9 || { echo "still running"; exit 0; }
```

`flock -n` fails at once if another process holds the lock; the lock is released when the script
exits. Alternatively, put it in the crontab: `* * * * * flock -n /tmp/job.lock /path/job.sh`.

### Other things to know

- `%` in a crontab command is special (newline). Escape it as `\%`, e.g. `date +\%F`.
- Debug with the log file first, then `grep CRON /var/log/syslog` (Debian/Ubuntu) or
  `journalctl -u cron`.
- On modern systems `systemd` timers are an alternative with better logging and missed-run catch-up.
- Test a schedule expression with a calculator such as [crontab.guru](https://crontab.guru/).

## Worked example

This script writes a cron-ready job, runs it the way cron would, shows `flock` skipping an
overlapping run, and prints sample crontab lines. It does not modify your crontab. Save as `cron.sh`.

```bash
#!/usr/bin/env bash
# cron.sh - what a cron-ready job looks like, and how to test it WITHOUT touching your crontab
set -euo pipefail

echo "--- 1. a job written for cron's bare environment"
cat > nightly.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin           # cron's PATH is minimal; set your own
lockfile="${LOCKFILE:-/tmp/nightly.lock}"
exec 9> "$lockfile"
if ! flock -n 9; then                              # a previous run is still going
    echo "nightly: previous run still active, skipping"
    exit 0
fi
echo "nightly: started (PATH=$PATH)"
sleep "${JOB_SECONDS:-0}"
echo "nightly: finished"
EOF
chmod +x nightly.sh

echo "--- 2. run it the way cron would: empty environment, different directory"
(cd / && env -i HOME=/nonexistent PATH=/usr/bin:/bin LOCKFILE="$OLDPWD/job.lock" bash "$OLDPWD/nightly.sh")

echo "--- 3. overlap protection: the second start is skipped while the first runs"
LOCKFILE="$PWD/job.lock" JOB_SECONDS=1 ./nightly.sh &
sleep 0.3
LOCKFILE="$PWD/job.lock" ./nightly.sh
wait

echo "--- 4. the crontab lines that would schedule it"
cat > crontab.txt <<'EOF'
# m   h  dom mon dow  command
30    2  *   *   *    /opt/jobs/nightly.sh >> /var/log/nightly.log 2>&1
*/15  9-17 *  *   1-5  /opt/jobs/check.sh
@reboot               /opt/jobs/start.sh
EOF
awk '!/^#/ && NF { if ($1 ~ /^@/) print "special: " $1; else print "schedule: " $1, $2, $3, $4, $5 }' crontab.txt
```

**Expected output**

```text
--- 1. a job written for cron's bare environment
--- 2. run it the way cron would: empty environment, different directory
nightly: started (PATH=/usr/local/bin:/usr/bin:/bin)
nightly: finished
--- 3. overlap protection: the second start is skipped while the first runs
nightly: started (PATH=/usr/local/bin:/usr/bin:/bin)
nightly: previous run still active, skipping
nightly: finished
--- 4. the crontab lines that would schedule it
schedule: 30 2 * * *
schedule: */15 9-17 * * 1-5
special: @reboot
```

The first run shows the minimal `PATH` the job set for itself. In section 3 the second invocation
started 0.3 seconds after the first one and was skipped, then the first finished.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Job works in the terminal, not in cron | Different `PATH` and working directory | Absolute paths; set `PATH` inside the script; test with `env -i` |
| `date +%F` in a crontab line | `%` means newline in a crontab | `date +\%F` |
| No output, no idea why it failed | stdout/stderr are discarded | `>> /path/job.log 2>&1` |
| Every-minute job that takes 3 minutes | Runs overlap and pile up | `flock -n` |
| `crontab -r` by accident | Deletes everything without asking | Back up with `crontab -l`; use `crontab -e` |
| Schedule `* 2 * * *` meaning "once at 02:00" | Minute `*` fires every minute of hour 2 | `0 2 * * *` |
| Forgetting the time zone | Job runs at the server's local time (often UTC) | Check `date`; set `CRON_TZ` if supported |

## Exercises

### Easy: write the schedules

Write these five schedules into a file (not your real crontab), one per line with a comment header:
daily at 02:30; every 15 minutes between 09:00 and 17:59 on weekdays; midnight on the first of each
month; Sundays at 03:00; and once at boot. Check that each line has the right number of fields
(6 or more, or 2 for `@reboot`).

**Acceptance criteria**

- Five `ok:` lines and `0 bad line(s)`.
- Schedules: `30 2 * * *`, `*/15 9-17 * * 1-5`, `0 0 1 * *`, `0 3 * * 0`, `@reboot`.
- The script exits non-zero if any line has too few fields.

### Medium: a cron-safe job

Write a job that takes its working directory as an absolute argument, sets its own `PATH`, sends all
output to `job.log`, and takes a lock so a second instance is skipped. Run it twice, 0.4 seconds
apart, each time via `cd / && env -i PATH=/usr/bin:/bin ...`, and print the log.

**Acceptance criteria**

- Log contains `start`, `skipped: previous run still active` and `done`, in that order.
- The second run exits with status 0 (skipping is not an error).
- Nothing is installed in any real crontab.

### Hard: a cron-expression matcher

Write `cron_match "M H DOM MON DOW" "YYYY-MM-DD HH:MM"` that returns success if the schedule would fire
at that moment. Support `*`, lists, ranges and steps (`*/15`, `0-30/10`); treat day-of-week `7` as
Sunday; use the OR rule when both day fields are restricted. Test it against at least ten cases.

**Acceptance criteria**

- `*/15 9-17 * * 1-5` matches `2025-10-10 09:30` (a Friday) but not the Saturday after it.
- `30 4 1,15 * *` matches the 15th and not the 16th.
- The script prints `N passed, 0 failed` and exits 1 if any test fails.

### Break it

This job works in your terminal but fails "under cron". Save as `break-it.sh`, run it, and fix
`job.sh` (written by the script) so both runs print the same.

```bash
#!/usr/bin/env bash
cat > job.sh <<'EOF'
#!/usr/bin/env bash
mytool
cat data.txt
EOF
mkdir bin
printf '#!/bin/sh\necho "mytool ok"\n' > bin/mytool
chmod +x bin/mytool bin/mytool
echo "report data" > data.txt
export PATH="$PWD/bin:$PATH"
job="$PWD/job.sh"

echo "--- as you run it in your terminal"
bash "$job"

echo "--- as cron runs it (bare PATH, working directory /)"
(cd / && env -i PATH=/usr/bin:/bin bash "$job")
```

**Expected output**

```text
--- as you run it in your terminal
mytool ok
report data
--- as cron runs it (bare PATH, working directory /)
/tmp/bash-lab/job.sh: line 2: mytool: command not found
cat: data.txt: No such file or directory
```

<details>
<summary>Hint</summary>

The terminal run has `./bin` on its `PATH` and runs inside the lab directory; the cron-style run has
neither. Pass the base directory as an argument and set `PATH` inside the job.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 20 easy: write five crontab lines to a file and sanity-check their shape.
# This does NOT install anything into your real crontab.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/crontab.txt" <<'EOF'
# m  h    dom mon dow  command
30   2    *   *   *    /opt/jobs/backup.sh >> /var/log/backup.log 2>&1
*/15 9-17 *   *   1-5  /opt/jobs/check.sh
0    0    1   *   *    /opt/jobs/monthly-report.sh
0    3    *   *   0    /opt/jobs/cleanup.sh
@reboot                /opt/jobs/start.sh
EOF

bad=0
while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    read -ra words <<< "$line"
    if [[ ${words[0]} == @* ]]; then
        need=2
    else
        need=6
    fi
    if (( ${#words[@]} >= need )); then
        echo "ok:  ${line}"
    else
        echo "BAD: ${line}"
        bad=$(( bad + 1 ))
    fi
done < "${work}/crontab.txt"

echo "${bad} bad line(s)"
rm -rf -- "$work"
(( bad == 0 ))
```

**Expected output**

```text
ok:  30   2    *   *   *    /opt/jobs/backup.sh >> /var/log/backup.log 2>&1
ok:  */15 9-17 *   *   1-5  /opt/jobs/check.sh
ok:  0    0    1   *   *    /opt/jobs/monthly-report.sh
ok:  0    3    *   *   0    /opt/jobs/cleanup.sh
ok:  @reboot                /opt/jobs/start.sh
0 bad line(s)
```

</details>

<details>
<summary>Medium</summary>

`exec 9> lock` opens file descriptor 9; `flock -n 9` locks it. After `exec >> "$log" 2>&1` all output of
the job goes to the log, which is how you would run it unattended.

```bash
#!/usr/bin/env bash
# Day 20 medium: a cron-safe job (own PATH, absolute paths, log file, lock) tested in a bare environment.
# Temporary files only; nothing is added to your crontab.
set -euo pipefail

work="$(mktemp -d)"

cat > "${work}/job.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
base="$1"                                  # absolute directory handed to us, no reliance on cwd
log="${base}/job.log"
exec 9> "${base}/job.lock"
exec >> "$log" 2>&1                        # from here on everything goes to the log

if ! flock -n 9; then
    echo "skipped: previous run still active"
    exit 0
fi
echo "start"
sleep "${JOB_SECONDS:-0}"
echo "done"
EOF

# Start a long run, then a second one while the first holds the lock.
(cd / && env -i PATH=/usr/bin:/bin JOB_SECONDS=1 bash "${work}/job.sh" "$work") &
sleep 0.4
(cd / && env -i PATH=/usr/bin:/bin bash "${work}/job.sh" "$work")
wait

echo "--- job.log"
cat "${work}/job.log"

rm -rf -- "$work"
```

**Expected output**

```text
--- job.log
start
skipped: previous run still active
done
```

</details>

<details>
<summary>Hard</summary>

The core is `field_matches`: split on commas, split off a `/step`, expand `*` to the field's min and
max, then test `(value - lo) % step == 0`. The `date -d` call turns a date into a weekday number.
`10#$2` forces base 10 so `08` and `09` are not read as invalid octal.

```bash
#!/usr/bin/env bash
# Day 20 hard: a tiny cron-expression matcher: does "m h dom mon dow" fire at "YYYY-MM-DD HH:MM"?
# Supports *, lists (1,15), ranges (9-17) and steps (*/15, 0-30/10). Pure Bash + date.
set -euo pipefail

# field_matches FIELD VALUE MIN MAX
field_matches() {
    local field="$1" value=$(( 10#$2 )) min="$3" max="$4"
    local part range step lo hi
    local -a parts
    IFS=, read -ra parts <<< "$field"
    for part in "${parts[@]}"; do
        range="${part%%/*}"
        step=1
        [[ $part == */* ]] && step="${part#*/}"
        if [[ $range == '*' ]]; then
            lo=$min; hi=$max
        elif [[ $range == *-* ]]; then
            lo="${range%-*}"; hi="${range#*-}"
        else
            lo="$range"; hi="$range"
        fi
        if (( value >= lo && value <= hi && (value - lo) % step == 0 )); then
            return 0
        fi
    done
    return 1
}

# cron_match "M H DOM MON DOW" "YYYY-MM-DD HH:MM"
cron_match() {
    local f_min f_hour f_dom f_mon f_dow day clock y mo d hh mm dow
    read -r f_min f_hour f_dom f_mon f_dow <<< "$1"
    read -r day clock <<< "$2"
    IFS=- read -r y mo d <<< "$day"
    IFS=: read -r hh mm <<< "$clock"
    dow="$(date -d "$day" +%w)"                        # 0 = Sunday

    field_matches "$f_min"  "$mm" 0 59 || return 1
    field_matches "$f_hour" "$hh" 0 23 || return 1
    field_matches "$f_mon"  "$mo" 1 12 || return 1
    # Classic cron rule: if BOTH day fields are restricted, either may match.
    local dom_ok=1 dow_ok=1
    field_matches "$f_dom" "$d" 1 31 && dom_ok=0 || true
    field_matches "${f_dow/7/0}" "$dow" 0 6 && dow_ok=0 || true
    if [[ $f_dom != '*' && $f_dow != '*' ]]; then
        (( dom_ok == 0 || dow_ok == 0 ))
    else
        (( dom_ok == 0 && dow_ok == 0 ))
    fi
}

passed=0 failed=0
check() {                                              # check EXPR WHEN EXPECTED(yes|no)
    local result=no
    cron_match "$1" "$2" && result=yes
    if [[ $result == "$3" ]]; then
        passed=$(( passed + 1 )); printf 'pass  %-18s %s -> %s\n' "$1" "$2" "$result"
    else
        failed=$(( failed + 1 )); printf 'FAIL  %-18s %s -> %s (wanted %s)\n' "$1" "$2" "$result" "$3"
    fi
}

check "*/15 9-17 * * 1-5" "2025-10-10 09:30" yes     # a Friday
check "*/15 9-17 * * 1-5" "2025-10-10 09:31" no      # not on the quarter hour
check "*/15 9-17 * * 1-5" "2025-10-11 09:30" no      # a Saturday
check "0 2 * * *"         "2025-10-10 02:00" yes
check "0 2 * * *"         "2025-10-10 02:01" no
check "30 4 1,15 * *"     "2025-10-15 04:30" yes
check "30 4 1,15 * *"     "2025-10-16 04:30" no
check "0 0 * * 0"         "2025-10-12 00:00" yes     # a Sunday
check "0 0 * * 7"         "2025-10-12 00:00" yes     # 7 also means Sunday
check "0-30/10 * * * *"   "2025-10-10 12:20" yes
check "0-30/10 * * * *"   "2025-10-10 12:40" no

echo "${passed} passed, ${failed} failed"
(( failed == 0 ))
```

**Expected output**

```text
pass  */15 9-17 * * 1-5  2025-10-10 09:30 -> yes
pass  */15 9-17 * * 1-5  2025-10-10 09:31 -> no
pass  */15 9-17 * * 1-5  2025-10-11 09:30 -> no
pass  0 2 * * *          2025-10-10 02:00 -> yes
pass  0 2 * * *          2025-10-10 02:01 -> no
pass  30 4 1,15 * *      2025-10-15 04:30 -> yes
pass  30 4 1,15 * *      2025-10-16 04:30 -> no
pass  0 0 * * 0          2025-10-12 00:00 -> yes
pass  0 0 * * 7          2025-10-12 00:00 -> yes
pass  0-30/10 * * * *    2025-10-10 12:20 -> yes
pass  0-30/10 * * * *    2025-10-10 12:40 -> no
11 passed, 0 failed
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `mytool` is found only because your terminal's `PATH` includes `./bin`; cron's does not, so the job
must set `PATH` itself. Bug 2: `cat data.txt` is a relative path, but cron starts in a different
directory; use an absolute path built from a base directory.

```bash
#!/usr/bin/env bash
# Fixed: the job sets its own PATH, uses absolute paths, and never relies on the working directory.
cat > job.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
base="$1"
export PATH="${base}/bin:/usr/local/bin:/usr/bin:/bin"
mytool
cat "${base}/data.txt"
EOF
mkdir bin
printf '#!/bin/sh\necho "mytool ok"\n' > bin/mytool
chmod +x bin/mytool
echo "report data" > data.txt
job="$PWD/job.sh"
base="$PWD"

echo "--- as you run it in your terminal"
bash "$job" "$base"

echo "--- as cron runs it (bare PATH, working directory /)"
(cd / && env -i PATH=/usr/bin:/bin bash "$job" "$base")
```

**Expected output**

```text
--- as you run it in your terminal
mytool ok
report data
--- as cron runs it (bare PATH, working directory /)
mytool ok
report data
```

</details>

Solution files live in [`solutions/day-20/`](solutions/day-20/).

## Self-check

1. What does `*/15 9-17 * * 1-5` mean?
2. Why does a script that works in your terminal fail under cron?
3. How do you capture a cron job's output?
4. What does `flock -n` do when the lock is already held?
5. Why is `crontab -r` dangerous?

<details>
<summary>Answers</summary>

1. Every 15 minutes during hours 9 to 17, Monday to Friday.
2. Cron has a minimal `PATH` and environment and starts in your home directory.
3. Redirect: `>> /path/job.log 2>&1`.
4. It fails immediately (non-zero status) instead of waiting, so the script can skip the run.
5. It removes the whole crontab without asking for confirmation.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `crontab -e`, `crontab -l` | Edit / list |
| `m h dom mon dow cmd` | Schedule format |
| `*/5`, `1,15`, `9-17`, `0-30/10` | Step, list, range, stepped range |
| `@reboot`, `@daily` | Shortcuts |
| `>> log 2>&1` | Keep output |
| `\%` | Literal percent |
| `env -i PATH=/usr/bin:/bin bash job.sh` | Test with cron's environment |
| `flock -n 9 \|\| exit 0` | Skip if already running |
| `crontab -l > backup` | Back up before changing |

## Further reading

- [crontab(5) manual (Debian)](https://manpages.debian.org/stable/cron/crontab.5.en.html): the
  authoritative description of the crontab file format.
- [flock(1) manual](https://man7.org/linux/man-pages/man1/flock.1.html): locking options, including
  `-n` and `-w`.
- [crontab.guru](https://crontab.guru/): type a schedule and read it back in plain English.
- [man7.org: crontab(5)](https://man7.org/linux/man-pages/man5/crontab.5.html): crontab file syntax and
  environment specifications.

**Next:** [Day 21](day-21.md)
