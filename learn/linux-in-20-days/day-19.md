# Day 19: Troubleshooting: "Something Is Broken, Now What?"

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md), [Day 12](day-12.md), [Day 13](day-13.md), [Day 15](day-15.md)

## Goal

By the end of this lesson you can:

- Apply a five-step method (observe, gather, hypothesise, change one thing, verify) instead of guessing.
- Turn a symptom (exit status, error text) into the next command to run.
- Find which process holds a port and stop exactly that process, and take a read-only triage snapshot of a machine.

## Concepts

### The method

1. **Observe precisely.** What exactly happens? Exact error text, exit status (`echo $?`), since when, what changed?
2. **Gather facts before touching anything.** Logs, state, permissions. Reading is free; changing destroys evidence.
3. **Hypothesise and test the cheapest, most likely cause first.** Work through the layers in order (Day 12): is it the machine, the network, the service, the config, the permissions?
4. **Change one thing at a time**, with an undo. If two changes fix it you will not know which mattered.
5. **Verify the original symptom is gone**, then write down cause and fix.

### Symptom to first commands

| Symptom | First checks |
|---------|--------------|
| `Permission denied` (exit 126 or 1) | `ls -l FILE`, `namei -l /full/path` (every directory on the path needs `x`), `id`, SELinux on RHEL: `ls -Z`, `ausearch -m avc -ts recent` |
| `command not found` (127) | `type CMD`, `echo "$PATH"`, is the package installed (Day 9)? |
| Service will not start | `systemctl status NAME`, `journalctl -u NAME -n 50 --no-pager`, `systemd-analyze verify` |
| `Address already in use` | `ss -ltnp 'sport = :PORT'` to see the holder |
| `No space left on device` | `df -h`, `df -i`, `du -h --max-depth=1 / \| sort -rh` (Day 8) |
| Machine is slow | `uptime`, `vmstat 1 5`, `ps -eo pid,pcpu,pmem,comm --sort=-pcpu \| head` (Day 13) |
| Cannot connect | address, route, name, port, HTTP, in that order (Day 12) |
| Works in terminal, fails in cron/systemd | environment: `PATH`, cwd, user, `%` (Day 16) |
| "It worked yesterday" | what changed: `journalctl --since yesterday`, package history (`/var/log/apt/history.log`, `dnf history`), config backups |

Exit statuses carry information: 126 found but not executable, 127 not found, 128+N killed by signal N (143 = SIGTERM, 137 = SIGKILL), 1 generic failure.

More tools when those are not enough: `bash -x script.sh` (prints each command as it runs), `lsof -p PID` (open files), `strace -f -e trace=file CMD` (which files a program touches; install the `strace` package, it was not available on the test machine and is not demonstrated).

> [!WARNING]
> Diagnosis is read-only; fixes are not. Before changing a config, copy it. Before killing a process,
> confirm its PID and command line. Never `chmod -R 777` or disable SELinux/firewalls "to see if that is
> the problem" on a machine other people use.

## Worked example

Scenario: a small web app will not start. The lab is a script that builds a broken app in a directory, with a throwaway server on `127.0.0.1` playing the "other process". Create it from the repository root of this course:

```bash
cd "$(mktemp -d)"
bash /path/to/solutions/day-19/break-it.sh lab
cd lab
```

**Expected output:**

```text
Lab created in lab. Try:   cd lab && ./start.sh
When you are done:          bash break-it.sh --cleanup lab
```

**Step 1: observe.**

```bash
./start.sh; echo "exit=$?"
```

**Expected output** (the first line is from your shell):

```text
bash: ./start.sh: Permission denied
exit=126
```

**Step 2: gather.** 126 means "found but cannot execute". Check the mode (the `namei` version shows the permission of every directory on the way):

```bash
ls -l start.sh | cut -d' ' -f1
```

```text
-rw-r--r--
```

No `x` anywhere. **Step 3-4: one change.**

```bash
chmod u+x start.sh
./start.sh; echo "exit=$?"
```

**Expected output:**

```text
./start.sh: line 7: PORT: PORT is not set in app.conf
exit=1
```

The symptom changed, so the first fault is fixed and there is a second one. Read the config:

```bash
cat app.conf
```

```text
PROT=<port>
DATA_DIR=./site
```

(`<port>` is the number your lab chose.) `PROT` is a typo. Fix it and try again; a time limit stops a server that does start from running for ever:

```bash
sed -i 's/^PROT=/PORT=/' app.conf
timeout 5 ./start.sh 2>&1 | tail -n 1
```

```text
OSError: [Errno 98] Address already in use
```

Third fault: something else holds the port. Ask the kernel who:

```bash
port=$(sed -n 's/^PORT=//p' app.conf)
ss -ltnp "sport = :$port"
```

**Expected output** (columns trimmed; PID differs):

```text
LISTEN ... users:(("python3",pid=<N>,fd=<N>))
```

That `python3` is the lab's blocker, whose PID is in `blocker.pid`. Stop that PID, not "all python":

```bash
kill "$(cat blocker.pid)"
./start.sh >/dev/null 2>&1 &
sleep 1
curl -s "http://127.0.0.1:$port/"
```

**Expected output:**

```text
<h1>app is up</h1>
```

**Step 5: verify and clean up.**

```bash
kill %1
cd ..
bash /path/to/solutions/day-19/break-it.sh --cleanup lab
```

```text
cleaned up lab
```

### A read-only triage snapshot

When someone says "the server is broken", start with one command that shows load, memory, disks, failed units, recent errors, listeners and top processes: [`solutions/day-19/hard.sh`](solutions/day-19/hard.sh). Sample output from the test machine (WSL 2; your values will differ, and the error lines shown are WSL noise):

```text
== load ==
cpus: 2
load (1/5/15 min): 16.96 5.68 2.01
== memory ==
               total        used        free      shared  buff/cache   available
Mem:            1904        1042          24           1         920         861
Swap:           2048        1257         790
== disk ==
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdf       1007G   15G  941G   2% /
inodes:
  / uses 1% of inodes
== units ==
failed units: 0
```

Here load (16.96 on 2 CPUs) and heavy swap use point at resource saturation, so the next step would be `ps` sorted by CPU and memory (Day 13).

**Undo:** the `--cleanup` command above stops the blocker and deletes the lab.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Changing several things at once | You will not know what fixed it, or what broke more | One change, one test |
| Fixing before reading the error | The message usually names the cause | Read it twice; copy it exactly into your notes |
| `pkill python3` to free a port | Kills every python process you own | Find the PID with `ss -ltnp` and kill that one |
| `chmod 777` / disabling the firewall to "test" | Opens the machine and hides the real cause | Find the exact bit or rule at fault |
| Trusting the first plausible cause | Faults often come in pairs, as in the lab | Re-run after each fix and expect a new symptom |
| Debugging on the production box without notes | You cannot undo what you did not record | Log commands and original values |
| Ignoring exit statuses | 126, 127 and 143 each point at different causes | `echo $?` right after the failure |

## Exercises

Reference solutions: [`solutions/day-19/`](solutions/day-19/). Everything runs on `127.0.0.1` in temporary directories.

### Easy

Using the lab, show that the first fault is exit status 126 caused by a missing execute bit, fix only that, confirm the status changes, and record a three-line note (`symptom:`, `cause:`, `fix:`).

**Acceptance criteria:**

- The note has exactly three lines.
- The exit status after the fix is not 126.
- You changed only the mode of `start.sh`.

### Medium

Start two local servers on free ports. Show that starting a third on the first port fails with "Address already in use", identify the PID holding that port with `ss -ltnp`, stop only it, and prove the other server still runs.

**Acceptance criteria:**

- The PID you found equals the one you started.
- The first port is free afterwards; the second still listens.
- You did not use `pkill` or `killall`.

### Hard

Write `triage.sh [--section NAME]` printing the sections `load memory disk units errors ports top`, each introduced by `== NAME ==`. Missing tools must print `n/a`, not fail.

**Acceptance criteria:**

- It finishes within 10 seconds and writes no files.
- `--section load` prints only that section (3 lines); an unknown section exits 2 with a message.
- It never uses `sudo`.

### Break it

The lab itself is the broken program: [`solutions/day-19/break-it.sh`](solutions/day-19/break-it.sh). It has three faults. Make `./start.sh` serve `<h1>app is up</h1>` using diagnosis only.

**Acceptance criteria:** `curl` returns the page; you can state each fault and the command that revealed it; you killed only the process holding the port.

## Solutions

<details>
<summary>Easy</summary>

```bash
./start.sh; echo $?          # 126
stat -c '%A %n' start.sh     # -rw-r--r-- start.sh
chmod u+x start.sh
```

Script: [`easy.sh`](solutions/day-19/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
holder=$(ss -ltnp "sport = :$p1" | grep -o 'pid=[0-9]*' | head -n 1 | cut -d= -f2)
kill "$holder"
```

`ss -p` shows process details for your own processes (root sees all). Capture the failing server's stderr into a variable before testing it, because `grep -q` in a pipeline closes early and `pipefail` then reports failure. Script: [`medium.sh`](solutions/day-19/medium.sh).

</details>

<details>
<summary>Hard</summary>

One function per section (`sec_load`, `sec_memory`...), a loop that calls `"sec_$name"`, and guards such as `command -v journalctl`. Script with `--self-test`: [`hard.sh`](solutions/day-19/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. Exit 126, `-rw-r--r--`: `chmod u+x start.sh`.
2. `PORT is not set`; `app.conf` says `PROT`: correct the key.
3. `Address already in use`; `ss -ltnp` shows the lab's blocker: `kill "$(cat blocker.pid)"`.

Scripted walkthrough that checks each step: [`break-it.fixed.sh`](solutions/day-19/break-it.fixed.sh).

</details>

## Self-check

1. What are the five steps of the method?
2. What does exit status 126 mean? 127? 143?
3. How do you find which process listens on port 8080?
4. Why change one thing at a time?
5. Why is `pkill python3` a poor way to free a port?

<details>
<summary>Answers</summary>

1. Observe, gather facts, hypothesise (cheapest first), change one thing, verify.
2. 126: found but not executable. 127: command not found. 143: killed by SIGTERM.
3. `ss -ltnp 'sport = :8080'` (or `lsof -i :8080`).
4. Otherwise you cannot tell which change helped or harmed, and you cannot undo cleanly.
5. It ends every python process you own, not just the one holding the port.

</details>

## Cheat sheet

```bash
echo $?                              # exit status of the last command
bash -x script.sh                    # trace every command
namei -l /full/path                  # permissions along a path
journalctl -u NAME -n 50 --no-pager; systemctl status NAME
ss -ltnp 'sport = :8080'             # who holds a port
df -h; df -i; uptime; free -m
ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head
lsof -p PID                          # open files
```

## Further reading

- [Brendan Gregg: Linux performance](https://www.brendangregg.com/linuxperf.html): the standard map of observability tools and which part of the system each one shows.
- [namei(1)](https://man7.org/linux/man-pages/man1/namei.1.html): follows a path and shows the permissions of every component.
- [strace(1)](https://man7.org/linux/man-pages/man1/strace.1.html): tracing system calls when logs give no answer.

**Next:** [Day 20](day-20.md)
