# Day 15: systemd Services and the Journal

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md), [Day 13](day-13.md)

## Goal

By the end of this lesson you can:

- Start, stop, enable and inspect services with `systemctl`, and say the difference between `start` and `enable`.
- Write, verify and run a `.service` unit file (as a user service without root), including automatic restart.
- Read logs with `journalctl` by unit, priority and time, and know where the system-wide (root) equivalents live.

## Concepts

`systemd` is PID 1 on every mainstream distribution (Debian, Ubuntu, Fedora, RHEL, Rocky, Alma...). It starts and supervises **units**: services (`.service`), timers (`.timer`, Day 16), mount points, sockets and more. `journald` collects their output.

### Essential commands

| Task | Command |
|------|---------|
| Is it running? | `systemctl status NAME` / `systemctl is-active NAME` |
| Start / stop / restart now | `sudo systemctl start\|stop\|restart NAME` |
| Reload config without restart | `sudo systemctl reload NAME` (if the service supports it) |
| Start at boot | `sudo systemctl enable NAME` (`--now` also starts it) |
| Don't start at boot | `sudo systemctl disable NAME` |
| What is broken? | `systemctl --failed` |
| See the unit file | `systemctl cat NAME` |
| Override safely | `sudo systemctl edit NAME` (creates a drop-in under `/etc/systemd/system/NAME.d/`) |
| Reread unit files | `sudo systemctl daemon-reload` |
| Property values | `systemctl show -p ActiveState -p NRestarts NAME` |

`start` and `enable` are independent: `start` affects the running system now; `enable` creates the symlink that starts it at boot. Service names differ by family: the SSH server is `ssh.service` on Debian/Ubuntu and `sshd.service` on RHEL-family systems.

### Where unit files live

| Directory | Meaning |
|-----------|---------|
| `/usr/lib/systemd/system/` | installed by packages (do not edit) |
| `/etc/systemd/system/` | yours (system-wide, root) |
| `~/.config/systemd/user/` | yours, run by your own user manager (`systemctl --user`), no root |

Today you work in the user directory, so everything is safe and reversible. The syntax is identical for system units.

### Anatomy of a service unit

```ini
[Unit]
Description=Linux in 20 days: hello service
# After= is ordering only; Wants=/Requires= create real dependencies.
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1
# Restart after a non-zero exit or a crash, not after a clean stop.
Restart=on-failure
RestartSec=2

[Install]
# User units use default.target; system units use multi-user.target.
WantedBy=default.target
```

Comments must be on their own line: systemd does not support text after a value on the same line (it would become part of the value).

`ExecStart` must start with an **absolute path**. `Type=simple` (default) means the process in `ExecStart` is the service; `Type=oneshot` is for run-to-completion jobs (and cannot use `Restart=always`).

### journald

```bash
journalctl -u NAME                 # one unit (add --user for user units)
journalctl -u NAME -f              # follow, like tail -f
journalctl -u NAME --since "10 min ago"
journalctl -b -p err               # this boot, priority error and worse
journalctl -k                      # kernel messages
journalctl --disk-usage            # how much space logs take
journalctl -o cat -u NAME          # message text only
```

The journal is a binary store, so you read it with `journalctl`, not `cat`. If `/var/log/journal` does not exist, logs are kept in memory only and vanish at reboot; create the directory (`sudo mkdir -p /var/log/journal`, then `sudo systemctl restart systemd-journald`) to make them persistent. As a normal user you see only your own logs unless you are in the `systemd-journal` (or `adm`) group.

## Worked example

Scenario: you have a small program that must run all the time, restart if it crashes, and log. We will run it as a user service. (If `systemctl --user` reports "Failed to connect to bus", your environment has no user manager: use a regular Ubuntu/Fedora VM, or WSL 2 with `systemd=true` in `/etc/wsl.conf`.)

Write the unit and have systemd check it before installing:

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/linux20-hello.service <<'EOF'
[Unit]
Description=Linux in 20 days: hello service

[Service]
ExecStart=/bin/sh -c 'echo "hello from the unit"; sleep 30'
Restart=on-failure

[Install]
WantedBy=default.target
EOF
systemd-analyze --user verify ~/.config/systemd/user/linux20-hello.service; echo "verify-rc=$?"
```

**Expected output:** (nothing printed by `verify` means the unit is fine)

```text
verify-rc=0
```

Load and start it, then inspect:

```bash
systemctl --user daemon-reload
systemctl --user start linux20-hello.service
sleep 1
systemctl --user is-active linux20-hello.service
systemctl --user show -p ActiveState -p SubState -p Restart linux20-hello.service
journalctl --user -u linux20-hello.service --no-pager -o cat
```

**Expected output:**

```text
active
ActiveState=active
SubState=running
Restart=on-failure
Started linux20-hello.service - Linux in 20 days: hello service.
hello from the unit
```

Now crash it on purpose. `systemctl kill -s KILL` sends SIGKILL to the service's process; because `Restart=on-failure`, systemd starts it again (the default `RestartSec` is 100 ms):

```bash
systemctl --user kill -s KILL linux20-hello.service
sleep 4
systemctl --user show -p NRestarts -p ActiveState linux20-hello.service
```

**Expected output:**

```text
ActiveState=active
NRestarts=1
```

Stop it, and see what `verify` says about a broken unit (no leading `/`):

```bash
systemctl --user stop linux20-hello.service
systemctl --user is-active linux20-hello.service
printf '[Service]\nExecStart=relative-command\n' > /tmp/linux20-bad.service
systemd-analyze --user verify /tmp/linux20-bad.service; echo "rc=$?"
```

**Expected output** (`is-active` prints `inactive` for a stopped service; stderr line first):

```text
inactive
linux20-bad.service: Command relative-command is not executable: No such file or directory
rc=1
```

For one-off jobs you do not need a file. `systemd-run` creates a *transient* unit and the journal still captures its output:

```bash
systemd-run --user --unit=linux20-demo --collect sh -c 'echo transient-ran; exit 0'
sleep 1
journalctl --user -u linux20-demo --no-pager -o cat
```

**Expected output** (the `Running as unit:` line includes an invocation ID that changes every time):

```text
Running as unit: linux20-demo.service; invocation ID: ...
Started linux20-demo.service - [systemd-run] /usr/bin/sh -c "echo transient-ran; exit 0".
transient-ran
```

Clean up everything you created:

```bash
rm -f ~/.config/systemd/user/linux20-hello.service /tmp/linux20-bad.service
systemctl --user daemon-reload
```

**Undo:** the commands above are the undo. Unit files removed + `daemon-reload` + stopped = the system is as before.

### The same thing for a real system service (root; not run for this lesson)

> [!WARNING]
> System services run as root unless you set `User=`. A mistake in a unit for `sshd`, networking or the
> display manager can make a machine unreachable. Edit units for critical services only through
> `systemctl edit` drop-ins, keep a second session open, and test on a VM.

```bash
sudo tee /etc/systemd/system/myapp.service >/dev/null <<'EOF'
[Unit]
Description=My app
After=network-online.target
Wants=network-online.target

[Service]
User=myapp
ExecStart=/opt/myapp/bin/myapp
Restart=on-failure
RestartSec=2
# Basic sandboxing; relax if the app needs more
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/lib/myapp

[Install]
WantedBy=multi-user.target
EOF
sudo systemd-analyze verify /etc/systemd/system/myapp.service
sudo systemctl daemon-reload
sudo systemctl enable --now myapp.service
systemctl status myapp.service
journalctl -u myapp.service -n 20 --no-pager
```

**Undo:** `sudo systemctl disable --now myapp.service && sudo rm /etc/systemd/system/myapp.service && sudo systemctl daemon-reload`. On RHEL-family systems with SELinux enforcing, a binary under `/opt` may need the right context (`ls -Z`, `journalctl -t setroubleshoot`) before systemd may execute it.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Edited the unit but nothing changed | systemd caches unit files | `systemctl daemon-reload`, then restart |
| `enable` but the service isn't running | `enable` only sets boot-time start | `enable --now`, or `start` |
| `ExecStart=myprog --flag` | Needs an absolute path; no shell | `ExecStart=/usr/bin/myprog --flag`, or `/bin/sh -c '...'` |
| Pipes and `$VAR` in `ExecStart` do not work | It is not a shell | Wrap in `/bin/sh -c '...'` or write a script |
| Typo such as `Restrat=` | Unknown keys are ignored with a warning | `systemd-analyze verify` before installing |
| `Restart=always` with `Type=oneshot` | Not allowed | `Restart=on-failure` or use a timer (Day 16) |
| "start request repeated too quickly" | Crash loop hit the start limit | Fix the crash; then `systemctl reset-failed NAME` |
| Looking for logs in `/var/log` only | Services log to the journal | `journalctl -u NAME` |
| Using `sshd` on Ubuntu or `ssh` on Rocky | Service names differ by family | `systemctl list-unit-files '*ssh*'` |

## Exercises

Reference solutions: [`solutions/day-15/`](solutions/day-15/). They use `systemctl --user`, so no root is needed, and they remove everything they create. They exit with status 77 (skipped) when no user manager exists.

### Easy

Write a user unit that prints a line and sleeps, verify it, start it and show its journal line. Remove the unit afterwards.

**Acceptance criteria:**

- `systemd-analyze --user verify` exits 0.
- `systemctl --user is-active` prints `active` while it runs.
- `journalctl --user -u` contains `hello from the unit`.
- After cleanup there is no unit file left.

### Medium

Show that `Restart=on-failure` works: start a transient service that exits with status 1 after one second and prove systemd restarted it at least once.

**Acceptance criteria:**

- `systemctl --user show -p NRestarts --value UNIT` prints a number of 1 or more.
- The unit is stopped and any failed state is cleared at the end.

### Hard

Write `unitlint.sh FILE` that prints `ERROR:` (exit 1) when `systemd-analyze verify` fails or there is no `ExecStart=`, and `WARN:` lines (exit 0) for a missing `Description=`, a long-running service without `Restart=`, or no `[Install]` section.

**Acceptance criteria:**

- A good unit produces no output and exit 0.
- A unit with only `ExecStart=/usr/bin/sleep 30` produces the three warnings and exit 0.
- A `Type=oneshot` + `Restart=always` unit produces an error and exit 1.

### Break it

[`solutions/day-15/break-it.sh`](solutions/day-15/break-it.sh) verifies a unit that has three problems. Fix the unit text until `verify` prints nothing and exits 0.

**Acceptance criteria:** `verify exit status: 0` and no output from `systemd-analyze`.

## Solutions

<details>
<summary>Easy</summary>

```bash
systemd-analyze --user verify ~/.config/systemd/user/NAME.service
systemctl --user daemon-reload && systemctl --user start NAME.service
journalctl --user -u NAME.service -o cat --no-pager
```

Script (uses `trap` to guarantee cleanup): [`easy.sh`](solutions/day-15/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
systemd-run --user --unit=linux20-d15-crashy --quiet \
  --property=Restart=on-failure --property=RestartSec=1 /bin/sh -c 'sleep 1; exit 1'
systemctl --user show -p NRestarts --value linux20-d15-crashy.service
```

Poll for up to a few seconds, because the first failure happens one second after the start. Script: [`medium.sh`](solutions/day-15/medium.sh).

</details>

<details>
<summary>Hard</summary>

Combine `systemd-analyze --user verify` (syntax, absolute paths, forbidden combinations) with simple `grep` checks for the style rules. `Type=` defaults to simple, so any unit whose `Type` is not `oneshot` and that lacks `Restart=` gets the warning. Script with `--self-test`: [`hard.sh`](solutions/day-15/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `Restart=always` is refused for `Type=oneshot`: use `Restart=on-failure`.
2. `Restrat=` is a typo that is silently ignored (only a warning); correct it to `Restart=`.
3. `ExecStart=report.sh` is not an absolute path: use `/full/path/report.sh`.

Fixed script: [`break-it.fixed.sh`](solutions/day-15/break-it.fixed.sh).

</details>

## Self-check

1. What is the difference between `systemctl start` and `systemctl enable`?
2. After editing a unit file, what must you run before restarting?
3. Why does `ExecStart=echo hi > /tmp/x` not work as written?
4. How do you see this boot's error-level log messages?
5. Where do you put your own system-wide unit files?

<details>
<summary>Answers</summary>

1. `start` runs it now; `enable` makes it start at boot. They are independent.
2. `systemctl daemon-reload`.
3. `ExecStart` is not run through a shell, so `>` is passed as an argument. Use `/bin/sh -c '...'`.
4. `journalctl -b -p err`.
5. `/etc/systemd/system/`.

</details>

## Cheat sheet

```bash
systemctl status NAME; systemctl is-active NAME; systemctl --failed
sudo systemctl enable --now NAME;  sudo systemctl disable --now NAME
sudo systemctl restart NAME;  sudo systemctl daemon-reload
systemctl cat NAME;  sudo systemctl edit NAME
systemd-analyze verify FILE.service
journalctl -u NAME -f;  journalctl -b -p err;  journalctl --since "1 hour ago"
systemd-run --user --unit=demo CMD          # transient unit, no file
systemctl --user ...                        # your own units, no root
```

## Further reading

- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html): every `[Service]` key, including `Type=` and `Restart=` semantics.
- [systemd.exec(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html): sandboxing and environment options such as `ProtectSystem=` and `User=`.
- [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html): filters, output formats and retention.
- [ArchWiki: systemd](https://wiki.archlinux.org/title/Systemd): a well-maintained practical reference, useful on any distribution.

**Next:** [Day 16](day-16.md)
