# Day 20: Capstone — Run, Back Up, and Recover a Web Service

> **Time:** ~90 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md), [Day 12](day-12.md), [Day 15](day-15.md), [Day 16](day-16.md), [Day 19](day-19.md)

## Goal

By the end of this lesson you can:

- Run a small web service as a **user systemd service**, verify it with a health check, and confirm it restarts after a crash.
- Schedule a **timer-driven backup**, verify the backup by restoring it, and compare the restored tree with the original.
- Diagnose a broken systemd unit (`systemd-analyze verify`) and fix the three classic mistakes: non-absolute `ExecStart`, `Type=oneshot` with `Restart=`, and the wrong `WantedBy=` target for a user manager.

Everything here runs as **your own user** under `systemctl --user`, on `127.0.0.1` only, inside a temporary directory. No root, no real disk, no network.

> [!WARNING]
> This lesson starts, stops and kills services and manipulates files. It is deliberately confined to a `mktemp -d` directory and loopback-only ports, but keep it out of any machine holding data you cannot lose.

## Concepts

### A user systemd service

Systemd can manage services for your own user, not just the whole machine:

- `systemctl --user start NAME` / `stop NAME` / `status NAME` — manage your user services.
- `systemd-analyze --user verify FILE` — check a unit file before loading it.
- Unit files live in `~/.config/systemd/user/`; run `systemctl --user daemon-reload` after adding or changing one.
- `Restart=on-failure` makes systemd restart the service if the main process exits with an error. `Type=simple` (the default) is right for a long-running server.

### A timer-driven backup with a verified restore

- A `.timer` unit triggers a `.service` unit on a schedule (`OnActiveSec=1s` in the lab means "one second after the timer starts").
- A backup is only real if you can restore it: extract the archive, `diff -r` against the original, and verify the `sha256sum`.
- `journalctl --user -u NAME` shows each backup run's output.

### The three unit bugs in the "break it" exercise

| Bug | Why systemd rejects it | Fix |
|-----|------------------------|-----|
| `ExecStart=python3 ...` (not an absolute path) | User services need the full path to the executable | `ExecStart=/usr/bin/python3 ...` |
| `Type=oneshot` with `Restart=always` | `oneshot` services run once and finish; `Restart=` is refused | Use `Type=simple` (delete the `Type=` line) |
| `WantedBy=multi-user.target` | That target does not exist in a user manager | `WantedBy=default.target` |

## Worked example

The capstone script [`solutions/day-20/capstone.sh`](solutions/day-20/capstone.sh) builds the whole thing in stages. Run each stage in a fresh temporary directory:

```bash
cd "$(mktemp -d)"
bash /path/to/this/repo/learn/linux-in-20-days/solutions/day-20/capstone.sh --stage 1
```

Replace `/path/to/this/repo/` with the actual path to your checkout of this repository.

**Stage 1: the service and its health check**

The script writes a Python HTTP server serving `site/index.html` on a random loopback port, installs a user unit, verifies it with `systemd-analyze --user verify`, starts it, and polls a health check until it reports `OK web is up`.

**Expected output:**

```text
OK web is up
PASS
```

The service answers on `127.0.0.1` only (`--bind 127.0.0.1`), and `Restart=on-failure` means it comes back if it crashes.

**Stage 2: timer-driven backup with verified restore**

The script adds a backup service and timer. The backup tars `site/`, writes a `sha256sum`, then restores to a fresh directory and `diff -r`s it against the original. The timer fires after one second and the script waits for the archive to appear.

**Expected output:**

```text
OK web is up
backup verified by restore
PASS
```

**Stage 3: failure drill**

The script sends `kill -9` to the service, waits for systemd to restart it (`NRestarts` becomes at least 1), confirms the health check is `OK` again, then stops the service and confirms the health check reports `CRITICAL` (exit 2).

**Expected output:**

```text
OK web is up
backup verified by restore
recovered after kill -9 (NRestarts=1)
health check reports CRITICAL (exit 2) while stopped
PASS
```

Run the whole thing (stages 1-3) with `capstone.sh --self-test` or no argument — that is the "Hard" solution.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `ExecStart=python3 ...` without a path | `systemd-analyze --user verify` refuses a non-executable relative name | Use `$(command -v python3)` |
| `Type=oneshot` + `Restart=always` | `oneshot` means "run once"; restarting is not allowed | `Type=simple` (the default) |
| `WantedBy=multi-user.target` | That target exists only in the system manager, not your user manager | `WantedBy=default.target` |
| Assuming `backup ok` in the journal means this run succeeded | Unit names repeat across runs, so old journal lines match | Wait for the archive file itself to appear |
| Killing "all python" to stop the service | Stops every python process you own | `systemctl --user stop linux20-cap-web.service` |

## Exercises

Reference solutions: [`solutions/day-20/`](solutions/day-20/). Everything runs as your user in a temporary directory; each script exits 77 (skipped) if `python3`, `curl`, `tar`, `sha256sum` or a user systemd manager is missing.

### Easy

Run [`easy.sh`](solutions/day-20/easy.sh) (stage 1). Confirm the service answers on loopback and that `systemctl --user status linux20-cap-web.service` shows it active.

**Acceptance criteria:**

- The health check prints `OK web is up` and exits 0.
- `curl http://127.0.0.1:$PORT/` returns `<h1>capstone</h1>`.
- The unit file is in `~/.config/systemd/user/linux20-cap-web.service` while the script runs and is removed afterwards.

### Medium

Run [`medium.sh`](solutions/day-20/medium.sh) (stages 1-2). Confirm the backup timer produces an archive, the `sha256sum` check passes, and the restored tree matches `site/`.

**Acceptance criteria:**

- An archive `backups/site-*.tar.gz` appears in the work directory.
- `sha256sum -c` on the `.sha256` file passes.
- `diff -r site restore/site` reports no differences.
- The script ends with `PASS`.

### Hard

Run [`hard.sh`](solutions/day-20/hard.sh) (stages 1-3, `--self-test`). Confirm the service recovers after `kill -9` and that the journal records the crash.

**Acceptance criteria:**

- Stages 1 and 2 pass (as in Medium).
- After `systemctl --user kill -s KILL`, `NRestarts` reaches at least 1 and the health check is `OK` again.
- `journalctl --user -u linux20-cap-web.service` contains a trace of the crash (`killed`, `SIGKILL`, or `Main process exited`).
- The script ends with `PASS`.

### Break it

Run [`break-it.sh`](solutions/day-20/break-it.sh). It installs a unit with the three classic bugs and runs `systemd-analyze --user verify`, which must report a non-zero exit. Then fix the unit (see [`break-it.fixed.sh`](solutions/day-20/break-it.fixed.sh)) until `verify` is silent and exits 0.

**Acceptance criteria:**

- The broken unit's verify exit status is non-zero.
- The fixed unit's verify exit status is 0 with no output.
- The fixed unit contains `WantedBy=default.target` and an absolute `ExecStart`.

## Grading rubric

Use this to score your own capstone, or have a peer score you. Each check lists the command that proves it.

| # | Requirement | Points | Verification command |
|---|-------------|--------|----------------------|
| 1 | Stage 1 service starts and answers on loopback | 20 | `curl -sf http://127.0.0.1:$PORT/` returns `<h1>capstone</h1>` |
| 2 | Unit verifies cleanly before starting | 15 | `systemd-analyze --user verify linux20-cap-web.service` exits 0, silent |
| 3 | Service restarts after `kill -9` (`NRestarts >= 1`) | 20 | `systemctl --user show -p NRestarts --value linux20-cap-web.service` >= 1 |
| 4 | Health check exits 0 when up, 2 when stopped | 10 | health-check script exit status |
| 5 | Timer produces a `site-*.tar.gz` archive | 10 | `compgen -G 'backups/site-*.tar.gz'` succeeds |
| 6 | Backup checksum verifies | 10 | `sha256sum -c archive.sha256` exits 0 |
| 7 | Restore matches the original (`diff -r` clean) | 10 | `diff -r site restore/site` exits 0 |
| 8 | Journal records the crash | 5 | `journalctl --user -u ...` shows `killed`/`SIGKILL` |
| | **Total** | **100** | |

80 points or more is a pass. Anything below 80 means re-run the stage that failed and read the unit's `systemctl --user status`.

## Solutions

<details>
<summary>Easy</summary>

Runs stage 1 only: installs the web unit, verifies it, starts it, polls the health check until `OK web is up`, then exits.

Script: [`easy.sh`](solutions/day-20/easy.sh).

</details>

<details>
<summary>Medium</summary>

Runs stages 1-2: adds the backup service and timer, waits for the archive, verifies the `sha256sum`, restores and `diff -r`s against the original.

Script: [`medium.sh`](solutions/day-20/medium.sh).

</details>

<details>
<summary>Hard</summary>

Runs the full capstone (stage 3): after the verified backup, kills the service with `kill -9`, waits for the automatic restart, confirms health, then stops it and confirms the health check reports critical.

Script: [`hard.sh`](solutions/day-20/hard.sh).

</details>

<details>
<summary>Break it</summary>

The broken unit has three faults:

1. `ExecStart=python3 ...` is not an absolute path.
2. `Type=oneshot` with `Restart=always` is refused.
3. `WantedBy=multi-user.target` does not exist in a user manager.

Fix: use `$(command -v python3)`, drop the `Type=` line (default `simple`), and use `WantedBy=default.target`.

Fixed, self-testing script: [`break-it.fixed.sh`](solutions/day-20/break-it.fixed.sh).

</details>

## Self-check

1. Where do user systemd unit files live, and what command reloads them after a change?
2. What is wrong with `Type=oneshot` combined with `Restart=always`?
3. Why does the backup script verify a `sha256sum` *and* restore to a separate directory?
4. What exit code does the health check report when the service is stopped, and what does that convention mean?
5. Which three bugs does `break-it.sh` contain?

<details>
<summary>Answers</summary>

1. `~/.config/systemd/user/`; `systemctl --user daemon-reload`.
2. `oneshot` services run once and finish, so `Restart=` is refused; a server is `Type=simple` (the default).
3. The checksum proves the archive is not corrupt; the restore proves the archive actually contains everything needed and can be extracted.
4. Exit 2; monitoring convention treats 2 as "critical" (down).
5. Non-absolute `ExecStart`; `Type=oneshot` with `Restart=always`; `WantedBy=multi-user.target` in a user manager.

</details>

## Cheat sheet

```bash
systemctl --user start NAME; systemctl --user status NAME
systemd-analyze --user verify FILE              # check a unit before loading it
systemctl --user daemon-reload                  # after adding/changing a unit file
journalctl --user -u NAME --no-pager -n 20      # recent logs for your service
systemctl --user kill -s KILL NAME              # crash the service on purpose
systemctl --user show -p NRestarts --value NAME # how many times it restarted
sha256sum -c archive.sha256                     # verify a backup
diff -r original restore                        # prove a restore matches
```

## Further reading

- [systemd.unit(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html): every section and key in a unit file.
- [systemd-analyze(1)](https://www.freedesktop.org/software/systemd/man/latest/systemd-analyze.html): verify, log-level and startup performance.
- [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html): reading user and system logs.

**Previous:** [Day 19](day-19.md)

**Next:** none — Day 20 is the capstone and the last day of the course. Continue with [30 Days of Bash](../30-days-of-bash/README.md) for scripting practice.
