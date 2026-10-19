# Day 27: Running Other Programs, Jobs and Timeouts

> **Time:** ~60 min · **Level:** Advanced
> **Prerequisites:** [Day 26](day-26.md)

## Goal

By the end of this lesson you can:

- Run other scripts and programs and capture their output and exit status separately.
- Start background jobs, `wait` for them and collect each one's result.
- Stop runaway commands with `timeout` and choose between `bash script`, `source` and `exec`.

## Concepts

### Dependencies first

Check that the tools you need exist before doing any work:

```bash
for tool in curl tar python3; do
    command -v "$tool" >/dev/null 2>&1 || { echo "missing: $tool" >&2; exit 127; }
done
```

`command -v` is the portable way to ask "does this exist?". Avoid `which`, whose output and
behaviour vary between systems.

### Three ways to run another script

| How | New process? | Shares your variables? | Typical use |
|-----|--------------|------------------------|-------------|
| `bash child.sh` / `./child.sh` | Yes | No (only exported ones flow *into* it) | Independent tools |
| `source child.sh` (or `. child.sh`) | No | Yes, both ways | Libraries, config |
| `exec child.sh` | Replaces your shell | n/a: your script ends | Wrapper scripts: "become" the real program |

A child cannot change your variables or directory. Its exit status comes back as `$?`.

### Capturing results

```bash
out="$(cmd 2>err.txt)" || status=$?      # stdout in $out, stderr in a file, status kept
cmd >out.txt 2>&1                         # both streams into one file
```

Always capture the status on the same line, because the next command overwrites `$?`.

### Background jobs and `wait`

`cmd &` starts a job and returns immediately; `$!` is its process ID. `wait PID` waits for that job and
returns **its** exit status.

```bash
slow_check & pid=$!
...                  # do other work meanwhile
wait "$pid" || echo "check failed"
```

- `wait` with no arguments waits for all jobs but loses individual statuses.
- `$?` right after `cmd &` is the status of *starting* the job (always 0), not of the job.
- Output from parallel jobs interleaves. Write each job's result to its own file, then print them in a
  fixed order.
- To limit parallelism, use `xargs -P N` (Day 17) or `wait -n` (wait for any one job).

### Timeouts and signals

```bash
timeout 5 slow_command            # kills it after 5 s; exit status 124
timeout -k 2 10 cmd               # send TERM at 10 s, KILL 2 s later if it ignores TERM
kill -TERM "$pid"                 # ask politely first; kill -9 cannot be cleaned up after
```

Exit statuses to recognise: `124` timed out, `127` command not found, `126` found but not executable,
`128+N` killed by signal N.

### Grouping: `{ }` versus `( )`

`{ cmds; }` runs in your shell (variables change); `( cmds )` runs in a **subshell** copy (nothing
leaks out). Use `( cd dir && ... )` to run something elsewhere without moving your script.

### Know when to use something else

Floating-point maths, JSON, dates in other time zones, HTTP APIs with authentication: reach for `awk`,
`jq`, `date -d`, or a short `python3 -c` line. Bash is glue, not a general-purpose language.

## Worked example

Seven demonstrations. Save as `ext.sh` and run it in an empty directory (needs `python3`).

```bash
#!/usr/bin/env bash
# ext.sh - calling other programs and scripts, capturing results, running jobs in parallel
set -euo pipefail

echo "--- 1. check dependencies before you need them"
missing=()
for tool in bash sed python3 no-such-tool; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
echo "missing: ${missing[*]:-none}"

echo "--- 2. three ways to run another script"
cat > child.sh <<'EOF'
#!/usr/bin/env bash
echo "child: sees VAR=${VAR:-<unset>}"
CHILD_RESULT="set by child"
exit 3
EOF
VAR="from parent"
status=0
bash child.sh || status=$?
echo "as a new process: exit status ${status}, CHILD_RESULT=[${CHILD_RESULT:-}]"
export VAR
bash child.sh || true
status=0
( source ./child.sh ) || status=$?
echo "sourced (in a subshell here): exit status ${status}"

echo "--- 3. capture stdout and stderr separately"
noisy() { echo "result data"; echo "warning: something odd" >&2; return 2; }
status=0
out="$(noisy 2>err.txt)" || status=$?
echo "stdout=[${out}] stderr=[$(< err.txt)] status=${status}"

echo "--- 4. background jobs: start them all, then wait for each and collect its status"
check() {                                   # check NAME DELAY RESULT
    sleep "$2"
    return "$3"
}
declare -A pid_of
check alpha 0.3 0 & pid_of[alpha]=$!
check beta  0.1 1 & pid_of[beta]=$!
check gamma 0.2 0 & pid_of[gamma]=$!
failed=0
for name in alpha beta gamma; do
    if wait "${pid_of[$name]}"; then
        echo "${name}: ok"
    else
        echo "${name}: FAILED"
        failed=$(( failed + 1 ))
    fi
done
echo "${failed} job(s) failed"

echo "--- 5. timeout stops a command that hangs (exit 124)"
status=0
timeout 1 sleep 5 || status=$?
echo "sleep 5 under timeout 1 -> status ${status}"

echo "--- 6. use the right tool: python3 for what Bash cannot do"
python3 -c 'import statistics as s; print("median:", s.median([3, 9, 4, 7]))'

echo "--- 7. a { } group shares your shell; a ( ) group is a copy"
counter=0
{ counter=10; }
( counter=99 )
echo "counter=${counter}"
```

**Expected output**

```text
--- 1. check dependencies before you need them
missing: no-such-tool
--- 2. three ways to run another script
child: sees VAR=<unset>
as a new process: exit status 3, CHILD_RESULT=[]
child: sees VAR=from parent
child: sees VAR=from parent
sourced (in a subshell here): exit status 3
--- 3. capture stdout and stderr separately
stdout=[result data] stderr=[warning: something odd] status=2
--- 4. background jobs: start them all, then wait for each and collect its status
alpha: ok
beta: FAILED
gamma: ok
1 job(s) failed
--- 5. timeout stops a command that hangs (exit 124)
sleep 5 under timeout 1 -> status 124
--- 6. use the right tool: python3 for what Bash cannot do
median: 5.5
--- 7. a { } group shares your shell; a ( ) group is a copy
counter=10
```

In section 2 the child's `CHILD_RESULT` never reaches the parent, while the sourced run shares
variables, and the exit status `3` comes back both times. Section 4 starts three jobs at once
and collects their statuses afterwards, in a fixed order.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `cmd &` then reading its output file at once | The job has not finished | `wait "$pid"` first |
| `echo $?` after `cmd &` | It is the status of starting the job (0) | `wait "$pid"; echo $?` |
| Script ends with jobs still running | They are orphaned or killed | `wait` before exiting |
| `./child.sh` and expecting it to set your variables | Child processes cannot | `source` it |
| `status=$?` on a separate line after `set -e` fails | The script already exited | `cmd \|\| status=$?` |
| `kill -9` as the first resort | No chance to clean up (traps do not run) | `kill -TERM`, then `-KILL` if needed |
| `which tool` in scripts | Different on every OS | `command -v tool` |
| Interleaved output from parallel jobs | Lines mix unpredictably | One result file per job, print in order |

## Exercises

### Easy: report a child's result

Write a child script that prints to stdout, prints a warning to stderr, and exits with status 4. In the
parent, capture stdout into a variable, stderr into a file and the status in a variable, print all
three, and map status 4 to `finished with skipped files`.

**Acceptance criteria**

- Output shows `stdout: 42 files processed`, `stderr: warning: 2 files skipped`, `exit status: 4`.
- The parent does not abort despite the non-zero status (`set -e` is on).
- Cleans up its temp directory.

### Medium: parallel checks

Simulate four service checks with `sleep` and exit codes (one takes 0.4 s, the fastest fails). Run them
in parallel, `wait` for each by PID, and print results in the order `database cache queue web`
regardless of which finished first, then the failure count.

**Acceptance criteria**

- Output order is fixed; `2 of 4 checks failed`.
- Each job writes its own result file; no output interleaving.
- Total runtime is about the slowest job (about 0.4 s), not the sum.

### Hard: `run_job` with timeouts

Write `run_job NAME LIMIT COMMAND...` that runs a command under `timeout`, classifies the status
(`0` ok, `124` timed out, `127` not found, anything else failed) and logs one line per job with `tee`.
Feed it four jobs from a here-document (`true`, `false`, `sleep 5` with a 1-second limit, and a missing
program).

**Acceptance criteria**

- Lines: `quick job: ok`, `failing job: failed with status 1`, `hanging job: TIMED OUT after 1s`,
  `missing tool: command not found`.
- Summary `3 of 4 jobs did not succeed` and the log has 4 lines.
- A timed-out job does not slow the script beyond its limit.

### Break it

This script has **two bugs**: the result file is read before it exists, and the printed exit status is
wrong. Save as `break-it.sh`, run it, and fix it so it prints `finished` and `job exit status: 3`.

```bash
#!/usr/bin/env bash
(sleep 0.3; echo finished > result.txt) &
cat result.txt 2>&1 || echo "result not ready"

(sleep 0.1; exit 3) &
echo "job exit status: $?"
wait
echo "all done"
```

**Expected output**

```text
cat: result.txt: No such file or directory
result not ready
job exit status: 0
all done
```

<details>
<summary>Hint</summary>

What does `cmd &` return to the shell, and which command pauses until a job is done?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 27 easy: run a child script and report its stdout, stderr and exit status separately.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/report.sh" <<'EOF'
#!/usr/bin/env bash
echo "42 files processed"
echo "warning: 2 files skipped" >&2
exit 4
EOF

run_and_report() {
    local script="$1" out status=0
    out="$(bash "$script" 2>"${work}/stderr.txt")" || status=$?
    echo "stdout: ${out}"
    echo "stderr: $(< "${work}/stderr.txt")"
    echo "exit status: ${status}"
    return "$status"
}

status=0
run_and_report "${work}/report.sh" || status=$?
case "$status" in
    0) echo "result: success" ;;
    4) echo "result: finished with skipped files" ;;
    *) echo "result: failure" ;;
esac

rm -rf -- "$work"
```

**Expected output**

```text
stdout: 42 files processed
stderr: warning: 2 files skipped
exit status: 4
result: finished with skipped files
```

</details>

<details>
<summary>Medium</summary>

Keeping the PIDs in an associative array lets us wait in any order we like. Because all four
jobs are already running, each `wait` returns as soon as that job is done.

```bash
#!/usr/bin/env bash
# Day 27 medium: run several health checks in parallel and report in a stable order.
# The "checks" are simulated with sleep so the script is self-contained and harmless.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

# check NAME DELAY EXIT_CODE : pretend to probe a service
check() {
    local name="$1" delay="$2" code="$3"
    sleep "$delay"
    if (( code == 0 )); then
        echo "ok" > "${work}/${name}.result"
    else
        echo "failed (code ${code})" > "${work}/${name}.result"
    fi
    return "$code"
}

declare -A pids
declare -a names=(database cache queue web)
check database 0.4 0 & pids[database]=$!
check cache    0.1 1 & pids[cache]=$!
check queue    0.3 0 & pids[queue]=$!
check web      0.2 2 & pids[web]=$!

failures=0
for name in "${names[@]}"; do                 # fixed order, whatever finishes first
    status=0
    wait "${pids[$name]}" || status=$?
    printf '%-9s %s\n' "$name" "$(< "${work}/${name}.result")"
    (( status == 0 )) || failures=$(( failures + 1 ))
done

echo "${failures} of ${#names[@]} checks failed"
```

**Expected output**

```text
database  ok
cache     failed (code 1)
queue     ok
web       failed (code 2)
2 of 4 checks failed
```

</details>

<details>
<summary>Hard</summary>

The job list is read from a here-document, so each line is `name|limit|command`. The `command -v`
check gives a clean "not found" verdict and avoids relying on `timeout`'s own message, which differs
between implementations. The command is split on spaces on purpose and is trusted.

```bash
#!/usr/bin/env bash
# Day 27 hard: run_job runs any command with a time limit, logs the result and maps exit codes.
# Safe: it only runs sleep, true and false.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
logfile="${work}/jobs.log"

# run_job NAME TIMEOUT_SECONDS COMMAND [ARGS...]
run_job() {
    local name="$1" limit="$2" status=0 verdict
    shift 2
    if command -v "$1" >/dev/null 2>&1; then
        timeout "$limit" "$@" || status=$?
    else
        status=127                              # check first: clearer than timeout's own message
    fi
    case "$status" in
        0)   verdict="ok" ;;
        124) verdict="TIMED OUT after ${limit}s" ;;
        127) verdict="command not found" ;;
        *)   verdict="failed with status ${status}" ;;
    esac
    printf '%s: %s\n' "$name" "$verdict" | tee -a "$logfile"
    return "$status"
}

total=0
failed=0
run_all() {
    local spec
    while IFS='|' read -r name limit cmd; do
        total=$(( total + 1 ))
        # shellcheck disable=SC2086   # deliberate word splitting of a simple, trusted command line
        run_job "$name" "$limit" $cmd || failed=$(( failed + 1 ))
    done
}

run_all <<'EOF'
quick job|2|true
failing job|2|false
hanging job|1|sleep 5
missing tool|2|definitely-not-installed
EOF

echo "--- summary: ${failed} of ${total} jobs did not succeed"
echo "log has $(wc -l < "$logfile") lines"
```

**Expected output**

```text
quick job: ok
failing job: failed with status 1
hanging job: TIMED OUT after 1s
missing tool: command not found
--- summary: 3 of 4 jobs did not succeed
log has 4 lines
```

</details>

<details>
<summary>Break it</summary>

Bug 1: the script read `result.txt` without waiting for the background job. Bug 2: `$?` after `&` is
0 because it only reports that the job was started. Capture `$!` and use `wait PID`.

```bash
#!/usr/bin/env bash
# Fixed: wait for the background jobs and read their status from wait, not from $?.
set -euo pipefail

(sleep 0.3; echo finished > result.txt) &
first=$!
wait "$first"
cat result.txt

(sleep 0.1; exit 3) &
second=$!
status=0
wait "$second" || status=$?
echo "job exit status: ${status}"
echo "all done"
```

**Expected output**

```text
finished
job exit status: 3
all done
```

</details>

Solution files live in [`solutions/day-27/`](solutions/day-27/).

## Self-check

1. What is the difference between `bash child.sh` and `source child.sh`?
2. What does `$!` hold?
3. What exit status does `timeout` return when the command is killed?
4. Why is `echo $?` right after `cmd &` misleading?
5. When does `exec cmd` return?

<details>
<summary>Answers</summary>

1. The first runs in a new process (no shared variables); the second runs in your shell.
2. The PID of the most recently started background job.
3. Exit status `124`.
4. It reports that the job was started, not how it finished; `wait PID` returns the real status.
5. Never: it replaces the shell process (unless the command cannot be started).

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `command -v tool` | Does it exist? |
| `bash x.sh` / `source x.sh` / `exec x.sh` | Child / same shell / replace shell |
| `out="$(cmd 2>err)" \|\| st=$?` | Capture output and status |
| `cmd & pid=$!` | Start in background |
| `wait "$pid"` | Wait and get that job's status |
| `wait -n` | Wait for any job |
| `timeout 5 cmd` | Limit runtime (124 on timeout) |
| `kill -TERM pid` | Ask to stop |
| `( cd dir && cmd )` | Run elsewhere without moving |

## Further reading

- [Greg's Wiki: ProcessManagement](https://mywiki.wooledge.org/ProcessManagement): background jobs,
  signals and process cleanup done properly.
- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html): the list of signals and their
  default actions.

**Next:** [Day 28](day-28.md)
