# Step 4: Shell Scripting for Administrators

> **Time:** ~6-8 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md) · **Next:** [Step 5: Package Management](step-05-package-mgmnt.md)

<!-- -->

> [!IMPORTANT]
> This step does **not** teach Bash from scratch. The full course is
> **[30 Days of Bash](../30-days-of-bash/)** (language, quoting, loops, functions, testing) and
> **[Linux in 20 Days](../linux-in-20-days/)**. Finish at least days 1-10 of 30 Days of Bash first.
> The tasks below apply those skills to real administration jobs.

<!-- -->

> [!WARNING]
> Tasks 4.5 and 4.6 create users and install software. Do this in a throwaway VM or the
> devcontainer, never on a machine you cannot afford to lose. Test scripts on a copy of the data first.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
All scripts here passed `shellcheck` and were run in an Ubuntu 24.04 container as root (Task 4.6 also on AlmaLinux 9).

## Script rules used in this repo

1. Start with `#!/usr/bin/env bash` and `set -euo pipefail`.
2. Quote every variable: `"$var"`. Use `--` before file names that might start with `-`.
3. Print errors to stderr (`>&2`) and exit non-zero.
4. Check input before acting. Use `[[ ... ]]`, not `[ ... ]`.
5. Make it safe to run twice (idempotent) and safe to fail halfway.
6. Run `shellcheck script.sh` before you trust it (`sudo apt install -y shellcheck` / `sudo dnf install -y ShellCheck` from EPEL).

---

## Beginner

### Task 4.1: Timestamped directory backups, scheduled with cron

- **What you will learn:** arguments with defaults, `tar` with a verified archive, and scheduling with `cron`.
- **Target distro:** both. cron service: `cron` (Debian/Ubuntu) or `crond` (RHEL, install `cronie`). Prefer a systemd timer for new jobs ([Step 10](step-10-automation.md)).
- **Risk level:** `safe` (reads the source, writes only to the destination).

```bash
mkdir -p ~/bin
cat > ~/bin/backup-dir.sh <<'EOF'
#!/usr/bin/env bash
# Usage: backup-dir.sh SOURCE_DIR [DEST_DIR]
set -euo pipefail
src="${1:?usage: backup-dir.sh SOURCE_DIR [DEST_DIR]}"
dest="${2:-$HOME/backups}"
[[ -d "$src" ]] || { echo "not a directory: $src" >&2; exit 1; }
mkdir -p -- "$dest"
stamp="$(date +%Y%m%d-%H%M%S)"
name="$(basename -- "$(realpath -- "$src")")"
archive="$dest/${name}-${stamp}.tar.gz"
tar -czf "$archive" -C "$(dirname -- "$(realpath -- "$src")")" -- "$name"
tar -tzf "$archive" >/dev/null          # integrity check
echo "created $archive"
EOF
chmod +x ~/bin/backup-dir.sh

mkdir -p ~/data/site && echo hi > ~/data/site/a.txt
~/bin/backup-dir.sh ~/data/site
ls ~/backups
```

Schedule it daily at 02:30 (the `%` must be escaped in crontab only if you use `date` there; this entry does not):

```bash
( crontab -l 2>/dev/null; echo '30 2 * * * $HOME/bin/backup-dir.sh $HOME/data/site >> $HOME/backups/backup.log 2>&1' ) | crontab -
crontab -l
```

**Verify it worked**

**Expected output:**

```text
created /tmp/bk/site-20261017-123625.tar.gz
```

(the path and time stamp are yours). `ls ~/backups` shows `site-<date>-<time>.tar.gz`.

**Acceptance criteria**

- [ ] Running with no argument prints a usage error and exits non-zero.
- [ ] The archive lists cleanly with `tar -tzf`.
- [ ] `crontab -l` contains the entry, and after the scheduled time `backup.log` has a line.

**Undo it**

```bash
crontab -l | grep -v backup-dir.sh | crontab -
rm -r ~/backups ~/data ~/bin/backup-dir.sh
```

**Troubleshooting**

- Works by hand, not in cron: cron has a tiny `PATH` and no `~`. Use absolute paths (`$HOME` works in the crontab line), and read `grep CRON /var/log/syslog` or `journalctl -u cron`.
- `crontab: command not found`: install `cron`/`cronie` and `systemctl enable --now cron` (`crond` on RHEL).
- Archive contains absolute paths: you used `tar -czf x /abs/path` without `-C`. The script above avoids it.

### Task 4.2: A system report (CPU, memory, disk)

- **What you will learn:** gathering data with `uptime`, `ps`, `free` and `df`, and redirecting a group of commands with `{ ...; } > file`. Use `ps` rather than parsing `top`, which is made for humans, not scripts.
- **Target distro:** both. **Risk level:** `safe` (read-only).

```bash
cat > ~/bin/sysreport.sh <<'EOF'
#!/usr/bin/env bash
# Print a short CPU / memory / disk report. Usage: sysreport.sh [OUTPUT_FILE]
set -euo pipefail
out="${1:-/dev/stdout}"
{
  echo "== System report: $(hostname) $(date '+%F %T') =="
  echo "-- Uptime / load --"
  uptime
  echo "-- CPU: top 5 processes --"
  ps -eo pid,pcpu,comm --sort=-pcpu | head -n 6
  echo "-- Memory --"
  free -h
  echo "-- Disk (real filesystems) --"
  df -hT -x tmpfs -x devtmpfs -x overlay 2>/dev/null || df -hT
} > "$out"
EOF
chmod +x ~/bin/sysreport.sh
~/bin/sysreport.sh
~/bin/sysreport.sh ~/report.txt && wc -l ~/report.txt
```

**Verify it worked**

**Expected output** (head of the report; numbers differ):

```text
== System report: 49e9ff20a4b5 2026-10-17 12:36:25 ==
-- Uptime / load --
 12:36:25 up 22 min,  0 user,  load average: 1.72, 1.13, 0.62
-- CPU: top 5 processes --
    PID %CPU COMMAND
      1  0.0 bash
```

**Acceptance criteria**

- [ ] The report has all four sections and a timestamp.
- [ ] Passing a file name writes the report there and prints nothing.
- [ ] You can explain why `ps --sort=-pcpu` is better than parsing `top` in a script.

**Undo it:** `rm ~/bin/sysreport.sh ~/report.txt`

**Troubleshooting**

- `df: unrecognized option` on BusyBox/Alpine: use `df -h` there.
- `hostname: command not found` on minimal images: use `uname -n`.
- Report shows only your script's processes in a container: containers see only their own process namespace.

### Task 4.3: A calculator that validates its input

- **What you will learn:** argument checks, regular expressions with `[[ =~ ]]`, `case`, `bc` for decimals, and meaningful exit codes. Never feed unchecked input to `bc` or `eval`.
- **Target distro:** both (`sudo apt install -y bc` / `sudo dnf install -y bc`). **Risk level:** `safe`.

```bash
cat > ~/bin/calc.sh <<'EOF'
#!/usr/bin/env bash
# Usage: calc.sh NUM1 OP NUM2     (quote * as '*')
set -euo pipefail
[[ $# -eq 3 ]] || { echo "usage: calc.sh NUM1 OP NUM2" >&2; exit 2; }
num='^-?[0-9]+([.][0-9]+)?$'
[[ $1 =~ $num && $3 =~ $num ]] || { echo "not a number" >&2; exit 2; }
case "$2" in
  +|-|'*') echo "scale=4; $1 $2 $3" | bc ;;
  /) [[ $3 =~ ^-?0+([.]0+)?$ ]] && { echo "division by zero" >&2; exit 1; }
     echo "scale=4; $1 / $3" | bc ;;
  *) echo "unknown operator: $2" >&2; exit 2 ;;
esac
EOF
chmod +x ~/bin/calc.sh
~/bin/calc.sh 7 + 5
~/bin/calc.sh 10 / 4
~/bin/calc.sh 3 '*' 2.5
~/bin/calc.sh 1 / 0; echo "rc=$?"
~/bin/calc.sh a + 1; echo "rc=$?"
```

**Verify it worked**

**Expected output:**

```text
12
2.5000
7.5
division by zero
rc=1
not a number
rc=2
```

**Acceptance criteria**

- [ ] Integers and decimals work; `/` shows 4 decimals.
- [ ] Bad numbers, bad operators and division by zero fail with a message on stderr and a non-zero code.
- [ ] `shellcheck calc.sh` is clean.

**Undo it:** `rm ~/bin/calc.sh`

**Troubleshooting**

- `*` expands to file names: quote it (`'*'`) or the shell globs it.
- `bc: command not found`: install `bc`. Pure-Bash alternative for integers: `$(( a + b ))`.
- Result `0` for `1 / 3`: you forgot `scale=`.

---

## Intermediate

### Task 4.4: Watch a log and alert on new matches

- **What you will learn:** remembering a byte offset between runs so only **new** lines are scanned, handling log rotation, and raising alerts via the system log (`logger`). From there, hand the journal entry to your monitoring system ([Step 7](step-07-system-monitoring.md)). Sending e-mail needs a configured MTA; `logger` needs nothing.
- **Target distro:** both. On journald-only systems read the journal instead: `journalctl -p err --since "-15 min"`.
- **Risk level:** `safe`.

```bash
cat > ~/bin/log-alert.sh <<'EOF'
#!/usr/bin/env bash
# Usage: log-alert.sh LOGFILE PATTERN [STATEFILE]
# Reports NEW matching lines since the last run; logs an alert via logger(1) and exits 1 if any.
set -euo pipefail
log="${1:?usage: log-alert.sh LOGFILE PATTERN [STATEFILE]}"
pattern="${2:?pattern required}"
state="${3:-/tmp/log-alert.$(basename -- "$log").offset}"
[[ -r "$log" ]] || { echo "cannot read $log" >&2; exit 3; }
size="$(stat -c %s -- "$log")"
offset=0
[[ -f "$state" ]] && offset="$(<"$state")"
(( offset > size )) && offset=0                 # log was rotated
matches="$(tail -c +"$((offset + 1))" -- "$log" | grep -Ei -- "$pattern" || true)"
echo "$size" > "$state"
if [[ -n "$matches" ]]; then
  count="$(wc -l <<< "$matches")"
  logger -t log-alert -p user.warning "$count new match(es) for '$pattern' in $log" 2>/dev/null || true
  echo "ALERT: $count new match(es) in $log"
  echo "$matches" | head -n 5
  exit 1
fi
echo "OK: no new matches in $log"
EOF
chmod +x ~/bin/log-alert.sh

printf 'ok line\nINFO fine\n' > /tmp/app.log
~/bin/log-alert.sh /tmp/app.log 'error|failed'; echo "rc=$?"
echo "Oct 17 ERROR disk full" >> /tmp/app.log
~/bin/log-alert.sh /tmp/app.log 'error|failed'; echo "rc=$?"
~/bin/log-alert.sh /tmp/app.log 'error|failed'; echo "rc=$?"
```

**Verify it worked**

**Expected output:**

```text
OK: no new matches in /tmp/app.log
rc=0
ALERT: 1 new match(es) in /tmp/app.log
Oct 17 ERROR disk full
rc=1
OK: no new matches in /tmp/app.log
rc=0
```

Then check the alert reached the journal: `journalctl -t log-alert -n 3`. On Debian/Ubuntu real auth failures
are in `/var/log/auth.log` (if `rsyslog` is installed), on RHEL in `/var/log/secure`.

**Acceptance criteria**

- [ ] The second run alerts once; the third run does not repeat it.
- [ ] A truncated or rotated log is handled (offset reset).
- [ ] Exit codes: 0 clean, 1 alert, 3 unreadable file.

**Undo it:** `rm ~/bin/log-alert.sh /tmp/app.log /tmp/log-alert.*.offset`

**Troubleshooting**

- Alerts repeat forever: the state file path is unwritable or changes each run.
- `/var/log/syslog` does not exist (RHEL, minimal Debian): use `/var/log/messages`, `/var/log/secure`, or `journalctl`.
- `logger` message missing: `journalctl -t log-alert`; some containers have no journald.

### Task 4.5: User management wrapper (add, remove, modify)

- **What you will learn:** turning a command and arguments into the right `useradd`/`usermod`/`userdel` call, validating names, and verifying the result. You already built `onboard`/`offboard` in [Task 2.8](step-02-user-and-group-mgmnt.md#task-28-automate-onboarding-and-offboarding); extend that script instead of starting over.
- **Target distro:** both. **Risk level:** `destructive` (it can delete accounts). Lab only.

Add a `modify` action to `/usr/local/sbin/user-lifecycle.sh` (insert before the `case`):

```bash
modify() {
  local user="$1" shell="$2"
  id "$user" &>/dev/null || die "no such user: $user"
  grep -qx -- "$shell" /etc/shells || die "not a valid login shell: $shell"
  usermod -s "$shell" "$user"
  [[ "$(getent passwd "$user" | cut -d: -f7)" == "$shell" ]] || die "verification failed"
  echo "$user now uses $shell"
}
```

and one case line: `modify) [[ $# -eq 3 ]] || die "usage: modify USER SHELL"; modify "$2" "$3" ;;`

**Verify it worked.** The `onboard`/`offboard` parts were run in Task 2.8. The `modify` function above was
*not run separately*; test it with:

```bash
sudo user-lifecycle.sh modify zoe /bin/sh && getent passwd zoe
```

*Typical output:* `zoe now uses /bin/sh` and a passwd line ending in `/bin/sh`.

**Acceptance criteria**

- [ ] Each action verifies its own result and fails loudly if it did not work.
- [ ] Invalid input (`../x`, unknown shell, unknown user) is rejected.
- [ ] `shellcheck` is clean.

**Undo it:** follow Task 2.8.

**Troubleshooting**

- `usermod: user zoe is currently used by process N` when changing UID/name: log the user out first.
- `not a valid login shell`: add the shell path to `/etc/shells` or use one already listed.
- Script works as root only: that is expected; wrap with `sudo` or install under `/usr/local/sbin`.

### Task 4.6: Automate installation and configuration (idempotent)

- **What you will learn:** one script that works on Debian/Ubuntu and RHEL family, installs packages non-interactively, writes config only when it changed, and restarts a service only when needed. This is the stepping stone to Ansible ([Step 10](step-10-automation.md)).
- **Target distro:** both (tested on Ubuntu 24.04 and AlmaLinux 9).
- **Risk level:** `can lock you out` if you configure `sshd` or the firewall this way. This example writes only a harmless file.

```bash
sudo tee /usr/local/sbin/provision.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Install packages and an idempotent config snippet; restart the service only when config changed.
# Usage: sudo provision.sh        Works on Debian/Ubuntu (apt) and RHEL family (dnf).
set -euo pipefail

packages=(jq tree)
conf_dir=/etc/lab
conf_file=$conf_dir/motd.conf

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }

if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq "${packages[@]}"
elif command -v dnf >/dev/null; then
  dnf install -y -q "${packages[@]}"
else
  echo "unsupported package manager" >&2; exit 1
fi

install -d -m 755 "$conf_dir"
new="$(mktemp)"
trap 'rm -f "$new"' EXIT
printf 'greeting=hello from %s\n' "$(hostname)" > "$new"

changed=0
if [[ ! -f "$conf_file" || "$(<"$new")" != "$(<"$conf_file")" ]]; then
  install -m 644 "$new" "$conf_file"
  changed=1
fi

if (( changed )); then
  echo "config updated"
  if command -v systemctl >/dev/null && systemctl is-active --quiet cron 2>/dev/null; then
    systemctl reload-or-restart cron      # replace with the service that reads your config
  fi
else
  echo "config already up to date"
fi
EOF
sudo chmod +x /usr/local/sbin/provision.sh
sudo provision.sh
sudo provision.sh
```

**Verify it worked**

**Expected output** (tail, same on both distros):

```text
config updated
config already up to date
```

then `command -v jq tree` prints `/usr/bin/jq` and `/usr/bin/tree`.

**Acceptance criteria**

- [ ] The second run changes nothing and says so.
- [ ] No prompts appear (non-interactive).
- [ ] `shellcheck` is clean.

**Undo it**

```bash
sudo rm -r /etc/lab /usr/local/sbin/provision.sh
sudo apt remove -y jq tree          # RHEL: sudo dnf remove -y jq tree
```

**Troubleshooting**

- `dnf` conflicts on `curl` vs `curl-minimal` (AlmaLinux/Rocky containers): do not install `curl` there, `curl-minimal` already provides the command. I hit this while testing.
- `cmp: command not found` on minimal RHEL images (diffutils missing): the script avoids `cmp` for this reason.
- `E: Could not get lock /var/lib/dpkg/lock`: another `apt` is running (often unattended-upgrades). Wait and retry.

---

## Advanced

### Task 4.7: Log analysis and reporting

- **What you will learn:** pipelines of `grep`, `sed -E`, `sort | uniq -c | sort -rn` and `awk` to summarise failed SSH logins by source and by hour. When logs get large, move to Loki or Wazuh ([Step 6](step-06-system-security.md), [Step 7](step-07-system-monitoring.md)).
- **Target distro:** both (auth log: `/var/log/auth.log` on Debian/Ubuntu, `/var/log/secure` on RHEL; or `journalctl -u ssh --no-pager`).
- **Risk level:** `safe` (read-only). Reports can contain user names and IPs, which is personal data: store them with mode `600`.

```bash
cat > ~/bin/log-report.sh <<'EOF'
#!/usr/bin/env bash
# Usage: log-report.sh LOGFILE...   Summarise failed SSH logins in auth-style logs.
set -euo pipefail
(( $# >= 1 )) || { echo "usage: log-report.sh LOGFILE..." >&2; exit 2; }
echo "== Failed SSH logins =="
grep -hE 'Failed password for' -- "$@" \
  | sed -E 's/.*Failed password for (invalid user )?([^ ]+) from ([0-9a-fA-F:.]+).*/\3 \2/' \
  | sort | uniq -c | sort -rn | head -n 10 \
  | awk '{printf "%-6s %-18s user=%s\n", $1, $2, $3}'
echo "== Failures per hour =="
grep -hE 'Failed password' -- "$@" | awk '{print $1, $2, substr($3,1,2)":00"}' | sort | uniq -c
EOF
chmod +x ~/bin/log-report.sh

cat > /tmp/auth.log <<'EOF'
Oct 17 10:01:02 h sshd[1]: Failed password for root from 203.0.113.5 port 22 ssh2
Oct 17 10:01:05 h sshd[1]: Failed password for root from 203.0.113.5 port 22 ssh2
Oct 17 10:02:00 h sshd[1]: Failed password for invalid user admin from 198.51.100.7 port 22 ssh2
Oct 17 11:15:00 h sshd[1]: Failed password for root from 203.0.113.5 port 22 ssh2
Oct 17 11:16:00 h sshd[1]: Accepted publickey for alice from 192.0.2.1 port 22 ssh2
EOF
~/bin/log-report.sh /tmp/auth.log
```

**Verify it worked**

**Expected output:**

```text
== Failed SSH logins ==
3      203.0.113.5        user=root
1      198.51.100.7       user=admin
== Failures per hour ==
      3 Oct 17 10:00
      1 Oct 17 11:00
```

The sample log uses documentation addresses. Three of the four failures happened between 10:00 and
10:59 (two from `203.0.113.5`, one for `admin`), which is why that hour shows 3.

**Acceptance criteria**

- [ ] Output matches the sample counts.
- [ ] The script accepts several files (including rotated `auth.log.1`).
- [ ] You can extend it to count `Invalid user` lines and top 3 usernames.

**Undo it:** `rm ~/bin/log-report.sh /tmp/auth.log`

**Troubleshooting**

- Empty report on a modern distro: SSH logs are in the journal only. Pipe it in: `journalctl -u ssh --no-pager | ./log-report.sh /dev/stdin` (unit is `sshd` on RHEL).
- Compressed rotated logs: use `zgrep` or `zcat file.gz | ...`.
- Wrong columns: log formats differ (syslog vs ISO 8601 timestamps). Adjust the `awk` field numbers.

### Task 4.8: Parallel processing

- **What you will learn:** splitting work, running workers in the background with `&`, waiting for each by PID so a failed worker is detected, and the simpler `xargs -P`. Bash has processes, not threads; the speed-up comes from using several CPU cores.
- **Target distro:** both (`split -n l/N` is in GNU coreutils). **Risk level:** `safe`.

```bash
cat > ~/bin/parallel-sum.sh <<'EOF'
#!/usr/bin/env bash
# Usage: parallel-sum.sh FILE [JOBS]   Sum the first column of FILE using JOBS parallel workers.
set -euo pipefail
file="${1:?usage: parallel-sum.sh FILE [JOBS]}"
jobs="${2:-4}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
split -n "l/$jobs" -- "$file" "$work/chunk."
pids=()
for chunk in "$work"/chunk.*; do
  awk '{s+=$1} END{print s+0}' "$chunk" > "$chunk.sum" &
  pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid"; done          # fail if any worker failed
cat "$work"/*.sum | awk '{t+=$1} END{print t+0}'
EOF
chmod +x ~/bin/parallel-sum.sh
seq 1 100000 > /tmp/nums
~/bin/parallel-sum.sh /tmp/nums 4
awk '{s+=$1} END{print s}' /tmp/nums

printf '%s\n' a b c d | xargs -P 4 -I{} sh -c 'echo "worker {}"' | sort
```

**Verify it worked**

**Expected output:**

```text
5000050000
5000050000
worker a
worker b
worker c
worker d
```

Both totals must agree. (For this tiny file the parallel version is not faster; use files of millions of lines to see a difference.)

**Acceptance criteria**

- [ ] Parallel and serial results are identical.
- [ ] If one worker is killed, the script exits non-zero (try `kill` on an `awk` while it runs on a large file).
- [ ] Temporary files are removed on exit (the `trap`).

**Undo it:** `rm ~/bin/parallel-sum.sh /tmp/nums`

**Troubleshooting**

- Output of workers interleaves: write each to its own file as above, or use `xargs -P` with `-n`.
- Too many processes: limit jobs to the CPU count (`nproc`).
- `split: invalid number of chunks`: `-n l/N` needs GNU `split` (not BusyBox).

### Task 4.9: Call an API with curl and jq

- **What you will learn:** `curl -fsS --max-time` (fail on HTTP errors, show errors, never hang), parsing JSON with `jq`, and acting on the result via exit codes. Never put tokens on the command line (visible in `ps`); read them from a file with mode `600`.
- **Target distro:** both (`sudo apt install -y jq curl` / `sudo dnf install -y jq`).
- **Risk level:** `safe` for read-only GET requests. Public APIs are rate limited and unauthenticated requests may be refused.

First, against a local JSON file so the result is predictable:

```bash
mkdir -p /tmp/api && cat > /tmp/api/status.json <<'EOF'
{"service":"web","status":"degraded","checks":[{"name":"db","ok":true},{"name":"cache","ok":false}]}
EOF
(cd /tmp/api && python3 -m http.server 8099 --bind 127.0.0.1 >/dev/null 2>&1 &)
sleep 1
curl -fsS --max-time 5 http://127.0.0.1:8099/status.json | jq -r '.checks[] | select(.ok | not) | "FAILING: \(.name)"'
curl -fsS --max-time 5 http://127.0.0.1:8099/status.json | jq -e '.status == "ok"' >/dev/null || echo "status not ok -> would alert"
```

Then a real public API (GitHub, no key, limited to 60 requests/hour per IP):

```bash
curl -fsS --max-time 10 https://api.github.com/repos/torvalds/linux | jq -r '"\(.full_name) default=\(.default_branch)"'
```

**Verify it worked**

**Expected output:**

```text
FAILING: cache
status not ok -> would alert
torvalds/linux default=master
```

**Acceptance criteria**

- [ ] The script exits non-zero when the API reports a failing check (`jq -e` sets the exit code).
- [ ] It never hangs (`--max-time`) and shows HTTP errors (`-f`).
- [ ] Your token (if any) is read from a `600` file, not typed on the command line.

**Undo it**

```bash
pkill -f "http.server 8099"; rm -r /tmp/api
```

**Troubleshooting**

- `curl: (22) The requested URL returned error: 403`: rate limit or missing `User-Agent`/token.
- `jq: error ... Cannot index string`: the API returned HTML or an error body; print it with `curl -sS` to see.
- `curl: (60) SSL certificate problem`: system CA bundle is missing (`ca-certificates` package). Never "fix" it with `-k`.

---

## Step checklist

- [ ] 4.1 Backup + cron
- [ ] 4.2 System report
- [ ] 4.3 Calculator
- [ ] 4.4 Log alert
- [ ] 4.5 User wrapper
- [ ] 4.6 Idempotent provisioning
- [ ] 4.7 Log analysis
- [ ] 4.8 Parallel processing
- [ ] 4.9 API automation

## Further reading

- [30 Days of Bash](../30-days-of-bash/): the full course in this repo.
- [ShellCheck](https://www.shellcheck.net/): paste a script and see what is wrong and why.
- [jq manual](https://jqlang.github.io/jq/manual/): filters, `select`, `-e` exit status.

**Next:** [Step 5: Package Management](step-05-package-mgmnt.md)
