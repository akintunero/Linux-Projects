# Day 16: Scheduling With cron and systemd Timers

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 14](day-14.md), [Day 15](day-15.md)

## Goal

By the end of this lesson you can:

- Read and write cron schedules, and name the five things that make a cron job behave differently from the same command in your terminal.
- Write a systemd timer + service pair, test its schedule with `systemd-analyze calendar`, and choose between cron and a timer.
- Stop a scheduled job from overlapping itself with `flock`.

## Concepts

### cron

`cron` runs commands at times described by five fields. Edit your own table with `crontab -e`, list it with `crontab -l`.

```text
# ┌ minute (0-59)
# │ ┌ hour (0-23)
# │ │ ┌ day of month (1-31)
# │ │ │ ┌ month (1-12 or jan-dec)
# │ │ │ │ ┌ day of week (0-7, 0 and 7 are Sunday; or sun-sat)
# │ │ │ │ │
  30 2 * * mon-fri  /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

| Piece | Meaning |
|-------|---------|
| `*` | every value |
| `1,15` | list |
| `9-17` | range |
| `*/10` | every 10th (minute 0, 10, 20...) |
| `@reboot`, `@daily`, `@hourly` | shortcuts |

Files in `/etc/cron.d/` and `/etc/crontab` have a **sixth field, the user name**, before the command. Scripts dropped in `/etc/cron.daily/` (and `.hourly`, `.weekly`, `.monthly`) run by name with no schedule syntax.

A cron job is **not** your interactive shell:

1. `SHELL` is `/bin/sh`, not bash.
2. `PATH` is minimal: use absolute paths, or set `PATH=` at the top of the crontab.
3. The working directory is your home, not where you were.
4. There is no terminal and no environment from your `.bashrc`.
5. A literal `%` means "newline": write `\%` (for example `date +\%F`).

Output not redirected is mailed to the user (if mail is configured) or lost. Always redirect: `>> /var/log/x.log 2>&1`.

### systemd timers

A timer is a unit that activates a service unit of the same name (`backup.timer` starts `backup.service`). Compared to cron:

| | cron | systemd timer |
|---|------|---------------|
| Logging | mail or your redirect | journal (`journalctl -u NAME`) automatically |
| Missed run (machine was off) | skipped (unless anacron) | `Persistent=true` runs it on next boot |
| Overlap | you must lock | a service is never started twice while active |
| Resource limits / sandbox | no | any service option |
| Random delay to spread load | no | `RandomizedDelaySec=` |
| Dependencies / ordering | no | yes |
| Complexity | one line | two files |
| Availability | everywhere, trivial | every systemd distro |

Rule of thumb: for one simple periodic command, cron is fine; for anything you must monitor, retry or sandbox, or that must catch up after downtime, use a timer.

`OnCalendar=` uses a different syntax from cron: `DayOfWeek Year-Month-Day Hour:Minute:Second`. Let systemd translate it with `systemd-analyze calendar` before you rely on it. Monotonic alternatives: `OnBootSec=5min`, `OnUnitActiveSec=1h`.

### Never overlap: flock

If a job can run longer than its interval, two copies may run together and corrupt data. `flock` takes a lock tied to an open file descriptor. If the holder dies for any reason, the kernel releases the lock, so there is no stale lock file.

## Worked example

Scenario: nightly backup at 02:30 on weekdays, and a health check every 15 minutes. First, let systemd confirm what the schedule expressions mean:

```bash
systemd-analyze calendar 'Mon..Fri 02:30' | sed -n 's/^ *Normalized form: //p'
systemd-analyze calendar '*:0/15'          | sed -n 's/^ *Normalized form: //p'
systemd-analyze calendar 'daily'           | sed -n 's/^ *Normalized form: //p'
systemd-analyze calendar 'nonsense'; echo "rc=$?"
```

**Expected output** (the last command prints an error on stderr first):

```text
Mon..Fri *-*-* 02:30:00
*-*-* *:00/15:00
*-*-* 00:00:00
Failed to parse calendar specification 'nonsense': Invalid argument
rc=1
```

`systemd-analyze calendar 'Mon..Fri 02:30'` without the `sed` also prints `Next elapse`, the next real date, so you can see whether it does what you meant.

Now a user timer that fires every two seconds, so you can watch it work (a real one would use `OnCalendar=`). Both files go in the user unit directory from Day 15:

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/linux20-tick.service <<'EOF'
[Unit]
Description=Linux in 20 days: tick

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo tick'
EOF
cat > ~/.config/systemd/user/linux20-tick.timer <<'EOF'
[Unit]
Description=Run tick every few seconds

[Timer]
OnActiveSec=1s
OnUnitActiveSec=2s
AccuracySec=100ms

[Install]
WantedBy=timers.target
EOF
cd ~/.config/systemd/user
systemd-analyze --user verify linux20-tick.timer linux20-tick.service; echo "verify-rc=$?"
systemctl --user daemon-reload
systemctl --user start linux20-tick.timer
sleep 6
journalctl --user -u linux20-tick.service --no-pager -o cat | grep -c '^tick$'
systemctl --user list-timers 'linux20-*' --no-pager --no-legend | wc -l
```

**Expected output** (the number of ticks varies with timing: it was 2 on one test run and 5 on another, so expect "at least 2"; the final `1` is the one timer listed):

```text
verify-rc=0
5
1
```

Clean up, which also stops the timer:

```bash
systemctl --user stop linux20-tick.timer
rm -f ~/.config/systemd/user/linux20-tick.service ~/.config/systemd/user/linux20-tick.timer
systemctl --user daemon-reload
```

For real timers you would write `OnCalendar=Mon..Fri 02:30` and `Persistent=true`, install system-wide in `/etc/systemd/system/` as root, and enable it with `sudo systemctl enable --now backup.timer` (view with `systemctl list-timers`).

Now overlap protection. This job takes two seconds; we start it twice at once:

```bash
cd "$(mktemp -d)"
cat > job.sh <<'EOF'
#!/usr/bin/env bash
exec 9>"${LOCK:-job.lock}"
if ! flock -n 9; then echo "already running, skipping"; exit 0; fi
echo "start"; sleep 2; echo "done"
EOF
bash job.sh & sleep 0.3; bash job.sh; wait
bash job.sh
```

**Expected output:**

```text
start
already running, skipping
done
start
done
```

The second copy skipped; once the first finished, the third run proceeded.

Finally, cron itself. **Only do this if `crontab -l` says "no crontab for you"**: `crontab -r` deletes *all* your entries without asking (and sits one key away from `-e`).

> [!WARNING]
> Never run `crontab -r` unless you mean to delete your whole crontab. Back up first:
> `crontab -l > ~/crontab.backup`. Restore with `crontab ~/crontab.backup`.

```bash
crontab -l
out=$(mktemp)
printf '* * * * * echo "SHELL=$SHELL" > %s\n' "$out" | crontab -
crontab -l | sed "s|$out|OUTFILE|"
sleep 70
cat "$out"
crontab -r
```

**Expected output** (for the first line: a fresh account has no crontab; after about a minute the file holds the shell cron used):

```text
no crontab for <your user>
* * * * * echo "SHELL=$SHELL" > OUTFILE
SHELL=/bin/sh
```

`SHELL=/bin/sh`, not bash: this is the first thing that surprises people. Cron also expands `%` as a newline. When tested, `date +%F > file` in a crontab produced an empty file, while `date +\%F > file` wrote the date.

**Undo:** `crontab -r` as above (or restore from your backup), and delete the temp file.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Command works in the terminal but not in cron | Minimal `PATH`, `/bin/sh`, different cwd | Absolute paths, set `PATH=`, `cd` inside the script |
| `date +%F` in a crontab does nothing useful | `%` is a newline in cron | `date +\%F` |
| `* 2 * * *` meant "once at 02:00" | Minute `*` = every minute during hour 2 | `0 2 * * *` |
| `0 */5 * * *` expected "every 5 hours from now" | Runs at hours 0, 5, 10, 15, 20 | Use a timer with `OnUnitActiveSec=5h` |
| Both day-of-month and day-of-week set | cron runs when **either** matches | Set one, `*` the other |
| No output and no idea why | Output was mailed or discarded | `>> /var/log/job.log 2>&1` |
| File in `/etc/cron.d` ignored | Missing user field, bad permissions, or a dot in the name | `0 2 * * * root cmd`, mode 0644, owned by root, name like `backup` |
| Overlapping runs | Job outlasts its interval | `flock -n`, or use a timer |
| Timer unit never fires | `.timer` not started/enabled, or no matching `.service` | `systemctl enable --now NAME.timer`; `systemctl list-timers` |

## Exercises

Reference solutions: [`solutions/day-16/`](solutions/day-16/). They do not touch your crontab; `easy.sh` needs `systemd-analyze` and `medium.sh` needs `flock`.

### Easy

Using `systemd-analyze calendar`, print the normalised form of `Mon..Fri 02:30`, `*:0/15` and `daily`, and show that `nonsense` is rejected.

**Acceptance criteria:**

- The three normalised forms are `Mon..Fri *-*-* 02:30:00`, `*-*-* *:00/15:00` and `*-*-* 00:00:00`.
- `systemd-analyze calendar 'nonsense'` exits non-zero.

### Medium

Write a job script with a lock so that a second copy started while the first runs prints `already running, skipping`, and prove that after `kill -9` of a running copy the next run is not blocked.

**Acceptance criteria:**

- The first run prints `done`; the overlapping run skips.
- After killing a run in the middle, the next run prints `done`.
- You used `flock -n` on a file descriptor, not a check-then-`touch`.

### Hard

Write `cronlint.sh [--system] FILE` that validates a crontab: five time fields or an `@keyword`, value ranges, lists, ranges, steps, month/day names, a non-empty command, and unescaped `%`. `--system` expects a user name before the command.

**Acceptance criteria:**

- A good file (comments, `NAME=value` lines, `*/15`, `mon-fri`, `jan,jul`, `date +\%F`, `@reboot`) gives no output and exit 0.
- `60 * * * *`, hour `24`, day `0`, month `13`, weekday `8`, range `5-1`, step `*/0`, a missing command and `date +%F` each produce a message with a line number, and the exit status is 1.
- A missing file gives a usage message and exit 2.

### Break it

[`solutions/day-16/break-it.sh`](solutions/day-16/break-it.sh) uses a lock *file* to avoid overlap. It has three bugs.

**Acceptance criteria:** two simultaneous runs do not both work; a killed run does not block later runs; the lock works regardless of the current directory.

## Solutions

<details>
<summary>Easy</summary>

```bash
systemd-analyze calendar 'Mon..Fri 02:30' | sed -n 's/^ *Normalized form: //p'
```

Script: [`easy.sh`](solutions/day-16/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
exec 9> "$LOCK"                 # open the lock file on descriptor 9
flock -n 9 || { echo "already running, skipping"; exit 0; }
```

The lock belongs to the open file description, so when the process dies (even with `kill -9`) the kernel drops it. Script: [`medium.sh`](solutions/day-16/medium.sh).

</details>

<details>
<summary>Hard</summary>

Split each line into five fields plus the command (`read -r f1 f2 f3 f4 f5 rest`), then validate each field by splitting on commas and checking each part as `*`, `N`, `A-B`, or any of those with `/STEP`. Replace month/day names by an in-range number first. Detect `%` by removing `\%` and testing what is left. Script with `--self-test`: [`hard.sh`](solutions/day-16/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `[ -f lock ]` followed by `touch` is two steps; two jobs can pass the test together. Use `flock -n`.
2. If the job dies, `rm $lock` never runs and the stale file blocks every future run. `flock` is released automatically.
3. `lock=job.lock` is relative to the current directory; cron starts in `$HOME`. Use one absolute path.

Fixed script: [`break-it.fixed.sh`](solutions/day-16/break-it.fixed.sh).

</details>

## Self-check

1. What does `*/10 * * * *` mean?
2. Why does `date +%F` fail in a crontab, and how do you fix it?
3. Which shell runs a cron command by default?
4. What does `Persistent=true` do in a timer?
5. Why is `flock` better than a lock file you create and delete yourself?

<details>
<summary>Answers</summary>

1. Every ten minutes (minutes 0, 10, 20, 30, 40, 50 of every hour).
2. `%` is turned into a newline; write `\%`.
3. `/bin/sh` (unless `SHELL=` is set in the crontab).
4. If the machine was off at the scheduled time, the missed run happens at the next start.
5. It is atomic and is released automatically when the process dies, so there are no races and no stale files.

</details>

## Cheat sheet

```bash
crontab -l                           # list      (backup: crontab -l > ~/crontab.backup)
crontab -e                           # edit
30 2 * * mon-fri CMD >> LOG 2>&1     # weekdays 02:30
*/15 * * * * CMD                     # every 15 minutes
@reboot CMD
systemd-analyze calendar 'Mon..Fri 02:30'    # check a timer expression
systemctl list-timers                        # all timers and next run
sudo systemctl enable --now backup.timer
flock -n /run/user/$UID/job.lock CMD         # no overlap
```

## Further reading

- [crontab(5)](https://man7.org/linux/man-pages/man5/crontab.5.html): the exact crontab syntax and environment rules (the `man7` copy follows the Vixie cron format).
- [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html): every timer option, including `Persistent=` and `RandomizedDelaySec=`.
- [systemd.time(7)](https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html): the full `OnCalendar` expression grammar.
- [flock(1)](https://man7.org/linux/man-pages/man1/flock.1.html): lock options, including timeouts and shared locks.

**Next:** [Day 17](day-17.md)
