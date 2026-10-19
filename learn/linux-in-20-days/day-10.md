# Day 10: Processes, Signals and Job Control

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 09](day-09.md)

## Goal

By the end of this lesson you can:

- List processes and read their state, parent, priority and command line.
- Stop a process politely (SIGTERM), pause it, and force it (SIGKILL) only when needed, and read the exit status.
- Run work in the background and write a script that cleans up after itself when it receives a signal.

## Concepts

A **process** is a running program with a PID, a parent (PPID), an owner and a state. Every process except PID 1 was started by another process. PID 1 (usually `systemd`) adopts orphans.

| State | Meaning |
|-------|---------|
| `R` | running or runnable |
| `S` | sleeping, waiting for something (normal) |
| `D` | uninterruptible I/O wait: it cannot be killed until the I/O returns |
| `T` | stopped (Ctrl+Z or SIGSTOP) |
| `Z` | zombie: finished, waiting for its parent to read the exit status. It uses no resources and cannot be killed; fix or end the parent |

### Looking

```bash
ps aux                              # all processes, BSD style
ps -ef --forest                     # all, with parent/child tree
ps -o pid,ppid,ni,state,comm -p PID # chosen columns for one process
pgrep -a nginx                      # find PIDs by name (-a: show command)
top        # or htop (install it); q quits, M sorts by memory, P by CPU
cat /proc/PID/status                # the kernel's own view
```

### Signals

A signal is a small message sent to a process.

| Signal | Number | Default effect | Use |
|--------|--------|----------------|-----|
| `SIGTERM` | 15 | terminate (can be caught: cleanup) | the polite request, `kill PID` |
| `SIGINT` | 2 | terminate | Ctrl+C |
| `SIGHUP` | 1 | terminate | many daemons reload their config on it |
| `SIGSTOP` / `SIGCONT` | 19 / 18 | pause / resume | `kill -STOP`, `kill -CONT` |
| `SIGKILL` | 9 | terminate **immediately**, cannot be caught | last resort |

`SIGKILL` skips cleanup: lock files stay, buffers are not flushed, child processes are orphaned. Try TERM first, wait a few seconds, then KILL.

A process that dies from signal N reports exit status `128 + N`, so SIGTERM is `143` and SIGKILL is `137`.

### Priority

`nice` runs a command at a niceness from -20 (greedy) to 19 (polite); default is 0. Only root may lower the number. `renice -n 5 -p PID` changes a running process.

### Job control in your shell

```bash
long-command &       # start in the background
jobs                 # list this shell's jobs
fg %1 / bg %1        # bring to front / resume in background
Ctrl+Z               # suspend the foreground job
nohup cmd &          # survive closing the terminal (see Day 17 for tmux, a better tool)
```

## Worked example

Scenario: a runaway job must be slowed, paused and stopped without side effects. We use `sleep` as the stand-in. Run these in one shell session.

Start it and inspect it:

```bash
sleep 300 &
pid=$!
ps -o ni=,state=,comm= -p "$pid"
grep -E '^(Name|State)' /proc/$pid/status
```

`$!` holds the PID of the last background job.

**Expected output** (spacing from `ps` may vary):

```text
  0 S sleep
Name: sleep
State: S (sleeping)
```

Lower its priority, then pause and resume it:

```bash
renice -n 5 -p "$pid" >/dev/null
ps -o ni= -p "$pid"
kill -STOP "$pid"; sleep 0.2; ps -o state= -p "$pid"
kill -CONT "$pid"; sleep 0.2; ps -o state= -p "$pid"
```

**Expected output:**

```text
  5
T
S
```

Stop it with SIGTERM and read the exit status with `wait`:

```bash
kill "$pid"
wait "$pid"
echo "exit=$?"
```

**Expected output:**

```text
exit=143
```

143 = 128 + 15: it died from signal 15.

Run something at low priority from the start (the `sh -c` prints its own niceness):

```bash
nice -n 10 sh -c 'ps -o ni= -p $$'
```

**Expected output:**

```text
 10
```

Now a script that cleans up when asked to stop. A `trap` runs a command when the signal arrives; `wait` is interruptible, so the trap fires immediately:

```bash
cat > trap-demo.sh <<'EOF'
#!/usr/bin/env bash
trap 'echo "cleaning up"; exit 3' TERM
sleep 100 &
wait $!
EOF
bash trap-demo.sh &
tp=$!
sleep 0.5
kill -TERM "$tp"
wait "$tp"
echo "exit=$?"
```

**Expected output:**

```text
cleaning up
exit=3
```

Finally, kill by command line. `pgrep -f`/`pkill -f` match the full command line, which keeps you from killing someone else's `sleep`:

```bash
sleep 200 &
sleep 201 &
pkill -f 'sleep 20[01]'
sleep 0.3
pgrep -f 'sleep 20[01]' | wc -l
```

**Expected output** (bash also prints job notices such as `Terminated` for the background jobs):

```text
0
```

> [!WARNING]
> Check what a pattern matches before you kill it: run `pgrep -af PATTERN` first. `pkill python` or
> `killall java` ends every such process you own (and, as root, every process on the machine). Never use
> `kill -9 1` or `kill -1` (that means "all processes").

**Undo:** you cannot un-kill a process. Restart the service (`sudo systemctl start NAME`, Day 15) and inspect its logs for what was lost.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `kill -9` as the first move | Skips cleanup: lock files, temp files, data in buffers | `kill PID`, wait, then `kill -9 PID` |
| `pid=$(pgrep sleep)` after starting a job | Matches any `sleep` on the system | Use `$!` straight after `&` |
| `echo $?` after `kill` to get the program's status | `$?` is `kill`'s own status | `wait PID; echo $?` |
| `ps aux \| grep nginx` lists the grep itself | The grep command line contains "nginx" | `pgrep -a nginx` or `grep '[n]ginx'` |
| Trying to kill a `Z` zombie | It is already dead | Look at its parent (`ps -o ppid= -p PID`) and restart that |
| `renice -5` as a normal user: "Permission denied" | Only root may raise priority | `sudo renice -n -5 -p PID` |
| Job disappears when the terminal closes | SIGHUP is sent to children | `nohup`, `setsid`, or tmux (Day 17) |

## Exercises

Reference solutions: [`solutions/day-10/`](solutions/day-10/). They only signal processes they start.

### Easy

Start `sleep 120` in the background, save its PID to `sleep.pid`, terminate it politely, and capture the exit status.

**Acceptance criteria:**

- `kill -0 PID` fails afterwards (the process is gone).
- The captured status is `143`.
- You used `$!`, not `pgrep`.

### Medium

Start two `sleep 4242` processes and one `sleep 4343` control. Terminate only the 4242 ones with one command.

**Acceptance criteria:**

- Both `sleep 4242` processes are gone.
- The `sleep 4343` process is still running.
- You matched on the command line (`pkill -f`), not just the name.

### Hard

Write `runlimit.sh SECONDS CMD...`: run CMD; after SECONDS send SIGTERM; if it is still alive 2 seconds later send SIGKILL. Do not use `timeout(1)`.

**Acceptance criteria:**

- A command that finishes in time passes its exit status through (`true` gives 0, `sh -c 'exit 7'` gives 7).
- A command that handles SIGTERM normally ends with status `124`.
- A command that ignores SIGTERM is killed and the status is `137`.
- No arguments gives a usage message and a non-zero status.

### Break it

[`solutions/day-10/break-it.sh`](solutions/day-10/break-it.sh) starts a worker whose `trap` deletes its lock file, then tries to stop it. There are three bugs.

**Acceptance criteria:** after your fix the lock file is gone and the script reports `worker exited with 3`.

## Solutions

<details>
<summary>Easy</summary>

```bash
sleep 120 &
echo $! > sleep.pid
pid=$(cat sleep.pid)
kill "$pid"
rc=0; wait "$pid" || rc=$?       # rc is 143
```

Script: [`easy.sh`](solutions/day-10/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
sleep 4242 & sleep 4242 & sleep 4343 &
pkill -f 'sleep 4242'
```

`-f` matches the whole command line, so the `4343` control is unaffected. Script: [`medium.sh`](solutions/day-10/medium.sh).

</details>

<details>
<summary>Hard</summary>

Run the command in the background and start a watcher subshell that sleeps, sends TERM, sleeps 2 and sends KILL. Create a flag file when the watcher fires so you can tell a timeout (status 143 plus flag, so return 124) from a command that happened to exit with 143 on its own. When the command finishes first, stop the watcher so it cannot signal a recycled PID.

```bash
(
  sleep "$limit"; : > "$flag"
  kill -TERM "$pid" 2>/dev/null || exit 0
  sleep 2; kill -KILL "$pid" 2>/dev/null
) &
```

Script with `--self-test`: [`hard.sh`](solutions/day-10/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `pgrep sleep` finds the `sleep` that the worker runs, not the worker. Use `$!`.
2. `kill -9` cannot be trapped, so the lock file remains. Send `TERM`.
3. `$?` after `kill` is `kill`'s status. Use `wait "$pid"; rc=$?`.

Fixed script: [`break-it.fixed.sh`](solutions/day-10/break-it.fixed.sh).

</details>

## Self-check

1. What exit status does a process killed by SIGTERM report?
2. Why is `kill -9` a last resort?
3. How do you get the PID of the job you just put in the background?
4. What does `kill -0 PID` do?
5. A process is in state `Z`. What can you do about it?

<details>
<summary>Answers</summary>

1. `143` (128 + 15).
2. SIGKILL cannot be caught, so the program cannot clean up: lock files, temp files and unwritten data are left behind.
3. `$!`.
4. Nothing to the process: it only tests whether it exists and you may signal it.
5. Nothing to the zombie itself; make its parent reap it (restart or fix the parent).

</details>

## Cheat sheet

```bash
ps aux; ps -ef --forest; pgrep -a NAME
kill PID                    # SIGTERM
kill -STOP PID; kill -CONT PID
kill -9 PID                 # last resort
pkill -f 'full command'     # match command line
sleep 100 & echo $!         # background job and its PID
wait PID; echo $?           # exit status (143 = SIGTERM)
nice -n 10 CMD; renice -n 5 -p PID
trap 'cleanup; exit' TERM INT
jobs; fg %1; bg %1; Ctrl+Z
```

## Further reading

- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html): the complete list of signals and which can be caught.
- [proc_pid_status(5)](https://man7.org/linux/man-pages/man5/proc_pid_status.5.html): what each field of `/proc/PID/status` means.
- [procps ps manual](https://man7.org/linux/man-pages/man1/ps.1.html): all `ps` output columns and process state codes.

**Next:** [Day 11](day-11.md)
