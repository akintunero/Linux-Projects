#!/usr/bin/env bash
# Day 10 - Easy: start a background sleep, save its PID, terminate it, and read its exit status.
# Safe: only touches the process it starts.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

sleep 120 &
echo $! > sleep.pid                  # $! is the PID of the most recent background job
pid=$(cat sleep.pid)
kill -0 "$pid"                       # signal 0 only tests that the process exists

kill "$pid"                          # SIGTERM (15): the polite request
rc=0; wait "$pid" || rc=$?
echo "exit status: $rc"

! kill -0 "$pid" 2>/dev/null         || { echo "FAIL: still running" >&2; exit 1; }
[[ $rc -eq 143 ]]                    || { echo "FAIL: expected 143 (128+15), got $rc" >&2; exit 1; }
echo PASS >&2
