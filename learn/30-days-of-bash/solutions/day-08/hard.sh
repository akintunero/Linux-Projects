#!/usr/bin/env bash
# Day 08 hard: run a command, show its output live, log it, and keep its exit status.
# Works in a temporary directory only.
set -euo pipefail

work="$(mktemp -d)"
logfile="${work}/job.log"

# run_logged LABEL COMMAND [ARGS...]
# stdout+stderr are shown AND appended to the log; the command's own status is returned.
run_logged() {
    local label="$1"
    shift
    echo "== ${label}: $*" | tee -a "$logfile"
    "$@" 2>&1 | tee -a "$logfile"
    local status="${PIPESTATUS[0]}"       # status of "$@", not of tee
    echo "== ${label}: exit ${status}" | tee -a "$logfile"
    return "$status"
}

run_logged greeting echo "hello from the job"
status=0
run_logged broken ls /no/such/dir || status=$?
echo "wrapper returned ${status}"

echo "--- lines in log: $(wc -l < "$logfile")"
grep -c '^== ' "$logfile" | sed 's/^/header lines: /'

rm -rf -- "$work"
