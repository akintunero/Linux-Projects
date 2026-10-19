# Day 13: Monitoring CPU, Memory, Disk and Load

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 12](day-12.md)

## Goal

By the end of this lesson you can:

- Read load average, `free`, `vmstat` and `top` output and say whether a machine is CPU-, memory-, disk- or I/O-bound.
- Find the process using the most CPU or memory.
- Turn the numbers into a one-line health snapshot with monitoring-style exit codes (0 OK, 1 warning, 2 critical).

## Concepts

### Ask the same four questions about every resource

The "USE" method: for CPU, memory, disk and network, check **U**tilisation (how busy), **S**aturation (is work queuing?) and **E**rrors.

| Resource | Utilisation | Saturation | Where to look |
|----------|-------------|------------|---------------|
| CPU | `%CPU` in `top`; `us`+`sy` in `vmstat` | load average above the CPU count; `r` column in `vmstat` | `uptime`, `vmstat 1`, `top` |
| Memory | `used` vs `available` in `free` | swapping: `si`/`so` columns in `vmstat` | `free -h`, `/proc/meminfo` |
| Disk space | `df -h` | `df -i` (inodes) | `df`, `du` (Day 08) |
| Disk I/O | `%util` from `iostat -x` | `wa` (I/O wait) in `vmstat` | `vmstat`, `iostat` (package `sysstat`) |

### Load average

`uptime` prints three numbers: average count of runnable (and, on Linux, uninterruptible) tasks over 1, 5 and 15 minutes. Compare to the number of CPUs from `nproc`: load 4.0 is fully busy on 4 CPUs but a 2x overload on 2 CPUs. A rising `1`-minute value above the `15`-minute value means it is getting worse.

### Memory: "free" is the wrong column

Linux uses spare memory as cache. Read **available**: what a new program could get without swapping. `free` low and `available` high is healthy. Sustained swap traffic (`si`/`so` above zero) or `available` near zero is trouble.

### Tools

```bash
uptime                      # load average
free -h                     # memory and swap
vmstat 1 5                  # one line per second, five lines (first line is the average since boot)
top -b -n 1 | head          # one batch snapshot of top
ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head      # biggest CPU users
ps -eo pid,rss,comm --sort=-rss | head             # biggest memory users (rss in kB)
cat /proc/pressure/cpu      # PSI: how much time tasks waited for CPU (kernel 4.20+)
```

`iostat`, `sar` and `mpstat` come from the `sysstat` package (`sudo apt install sysstat` or `sudo dnf install sysstat`); they were not installed where this lesson was tested, so they are described, not demonstrated. `htop` is a friendlier `top` (`sudo apt install htop`).

## Worked example

Scenario: someone reports "the server is slow". You have two minutes to say whether it is CPU, memory or something else. First, the baseline. Output depends on your machine; this is a real sample from a 5-CPU, 2 GB WSL 2 instance, so compare the *shape*, not the numbers.

```bash
uptime | sed 's/^.*load average/load average/'
free -m | head -n 2
vmstat 1 3
```

**Sample output:**

```text
load average: 1.40, 1.57, 1.08
               total        used        free      shared  buff/cache   available
Mem:            1904         911         360           3         723         992
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 1  0  16672 369224 109404 631816    2   18   838  2506 2007   20  6 12 81  1  0  0
 0  0  16672 369440 109404 631856    0    0     0     0 2166 4390  1 15 84  0  0  0
 0  0  16672 371296 109404 631856    0    0     0    12 1736 3382  1 14 85  0  0  0
```

Reading it: `r` (runnable) is 0-1, `id` (idle) 81-85%, `si`/`so` near 0 and `available` is about half of the total, so nothing is saturated. If `r` were consistently above the CPU count and `id` near 0, you would have CPU saturation; if `wa` were high, the disk; if `so` were busy, memory.

Now create a CPU hog and find it the way you would on a real incident. `yes > /dev/null` spins one CPU:

```bash
yes > /dev/null &
hog=$!
sleep 2
ps -eo pid=,pcpu=,comm= --sort=-pcpu | head -n 1 | awk '{print $3}'
```

**Expected output:**

```text
yes
```

(`ps` reports the average CPU use since the process started, so wait a moment after starting a process.)

Stop it, then create a memory hog the same way. This Python one-liner allocates and touches 200 MB for 3 seconds:

```bash
kill "$hog"
python3 -c 'import time; x = bytearray(200*1024*1024); x[::4096] = b"a" * len(x[::4096]); time.sleep(3)' &
big=$!
sleep 1.5
ps -o rss= -p "$big" | awk '{print ($1 > 200000 ? "rss over 200 MB" : "rss under 200 MB")}'
kill "$big" 2>/dev/null
```

**Expected output:**

```text
rss over 200 MB
```

`RSS` is the resident set size in kilobytes. Use `ps -eo pid,rss,comm --sort=-rss | head` to find the biggest users.

Finally, the kernel's pressure-stall numbers tell you directly how much time tasks waited, which is more honest than load average. The first line shows time when *some* tasks stalled (sample):

```bash
cat /proc/pressure/cpu
```

```text
some avg10=2.23 avg60=2.94 avg300=4.15 total=50063363
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
```

Put the numbers together in [`solutions/day-13/hard.sh`](solutions/day-13/hard.sh), a script that prints one line (`OK load_pct=25 mem_pct=10 disk_pct=10`) and exits 0, 1 or 2 so a scheduler or monitoring system can act on it.

> [!NOTE]
> `kill` on a process you started is safe. Never "fix" a slow server by killing the highest-CPU process
> blindly: it may be the database. Identify it first (`ps -fp PID`), then decide.

**Undo:** the hogs were killed above; nothing persisted.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Reading `free` as "memory is full" | Cache is counted as used | Read the `available` column |
| `uptime \| awk '{print $10}'` for load | Column position moves with days/users | `awk '{print $1}' /proc/loadavg` |
| `[ $load -gt $cpus ]` | `[ ]` cannot compare decimals like `3.40` | `awk -v c=$cpus '{exit !($1 > c)}' /proc/loadavg` |
| Treating load 4 as bad everywhere | Load must be compared with CPU count | Divide by `nproc` |
| `ps` %CPU "is 0" for a new hog | `ps` averages over the process's lifetime | Wait a few seconds, or use `top` |
| First `vmstat` line looks odd | It is the average since boot | Ignore it; read lines 2+ |
| Looking only at CPU when everything is slow | Could be I/O wait or swapping | Check `wa` and `si`/`so` |

## Exercises

Reference solutions: [`solutions/day-13/`](solutions/day-13/). All are read-only.

### Easy

Compute the percentage of memory in use as `(MemTotal - MemAvailable) / MemTotal` from `/proc/meminfo` with `awk`.

**Acceptance criteria:**

- The result is a whole number from 0 to 100.
- For a fixture file with `MemTotal: 1000 kB` and `MemAvailable: 250 kB` it prints `75`.

### Medium

Write `topcpu.sh [N]` that prints the N busiest processes (default 5) as `PID %CPU COMMAND`, without a header line.

**Acceptance criteria:**

- Starting `yes > /dev/null` and waiting 2 seconds puts its PID in the top 3.
- `N` must be a positive integer; `0` or `abc` gives an error and a non-zero status.

### Hard

Write `snapshot.sh [WARN [CRIT]]` that prints `STATE load_pct=.. mem_pct=.. disk_pct=..` and exits 0 (OK), 1 (WARNING, worst metric at or above WARN, default 80) or 2 (CRITICAL, at or above CRIT, default 95). `load_pct` is the 1-minute load as a percentage of the CPU count; `disk_pct` is for `/`.

**Acceptance criteria:**

- With fixtures you can force each state (use overrides such as `LOADAVG=file MEMINFO=file NPROC=n DISK_PCT=n`).
- WARN must be less than CRIT, otherwise exit 64 with a usage message.
- It reads only; no `sudo`.

### Break it

[`solutions/day-13/break-it.sh`](solutions/day-13/break-it.sh) should print `OVERLOADED` when load exceeds the CPU count, and the percentage of memory really in use. It has three bugs.

**Acceptance criteria:** with `NPROC=4` and a load of `6.50` it prints `OVERLOADED`; with `0.50` it prints `load ok`; memory used excludes reclaimable cache.

## Solutions

<details>
<summary>Easy</summary>

```bash
awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {printf "%d\n", (t - a) * 100 / t}' /proc/meminfo
```

Script: [`easy.sh`](solutions/day-13/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
ps -eo pid=,pcpu=,comm= --sort=-pcpu | head -n "$n"
```

The `=` after each column name suppresses the header. Script with `--self-test`: [`medium.sh`](solutions/day-13/medium.sh).

</details>

<details>
<summary>Hard</summary>

Compute the three percentages, take the maximum, map it to a state with two thresholds and `return` the matching exit code. Reading inputs from overridable variables (`${LOADAVG:-/proc/loadavg}`) is what makes it testable without producing real load. Script with `--self-test`: [`hard.sh`](solutions/day-13/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `uptime | awk '{print $10}'` picks a movable column and includes a comma. Use the first field of `/proc/loadavg`.
2. `[ $load -gt $cpus ]` cannot compare decimals. Compare in awk: `awk -v c="$cpus" '{exit !($1 > c)}'`.
3. `MemFree` ignores reclaimable cache; use `MemAvailable`.

Fixed script: [`break-it.fixed.sh`](solutions/day-13/break-it.fixed.sh).

</details>

## Self-check

1. A 4-CPU machine has a load average of 2.0. Is it saturated?
2. Which `free` column tells you how much memory a new program can get?
3. What do non-zero `si`/`so` in `vmstat` indicate?
4. Why is the first line of `vmstat` ignored?
5. Which package provides `iostat` and `sar`?

<details>
<summary>Answers</summary>

1. No: 2.0 on 4 CPUs is about 50% utilisation.
2. `available`.
3. The system is swapping pages in and out: memory pressure.
4. It is the average since boot, not the current rate.
5. `sysstat`.

</details>

## Cheat sheet

```bash
nproc; uptime; cat /proc/loadavg
free -h; grep -E '^(MemTotal|MemAvailable)' /proc/meminfo
vmstat 1 5                          # r b swpd si so wa id
top -b -n 1 | head -n 15
ps -eo pid,pcpu,comm --sort=-pcpu | head
ps -eo pid,rss,comm  --sort=-rss  | head
df -h /; df -i /
cat /proc/pressure/cpu              # PSI
iostat -x 1 3                       # needs sysstat
```

## Further reading

- [proc_loadavg(5)](https://man7.org/linux/man-pages/man5/proc_loadavg.5.html): exactly what the five fields of `/proc/loadavg` are.
- [vmstat(8)](https://man7.org/linux/man-pages/man8/vmstat.8.html): every vmstat column explained.
- [Kernel PSI documentation](https://docs.kernel.org/accounting/psi.html): how pressure-stall information works and how to read it.
- [Brendan Gregg: the USE method](https://www.brendangregg.com/usemethod.html): the checklist approach used in this lesson, with Linux examples.

**Next:** [Day 14](day-14.md)
