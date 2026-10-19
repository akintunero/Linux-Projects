#!/usr/bin/env bash
# Day 10 - Hard: runlimit.sh SECONDS CMD... - run CMD; after SECONDS send SIGTERM, and if it is
# still alive 2 seconds later send SIGKILL. The exit status is the command's own, or 124 when the
# time limit fired (like timeout(1)), or 137 when SIGKILL was needed.
# Usage: hard.sh 5 sleep 30 | hard.sh --self-test
# Safe: only signals the process it started.
set -uo pipefail

runlimit() {
  # ${1:?msg} would exit the whole shell in a script, so test the argument count instead.
  (($# >= 2)) || { echo "usage: runlimit SECONDS CMD..." >&2; return 2; }
  local limit=$1; shift
  [[ $limit =~ ^[0-9]+$ ]] || { echo "SECONDS must be a whole number" >&2; return 2; }

  local flag; flag=$(mktemp -u)          # the watcher creates this file when the limit fires
  "$@" &
  local pid=$! watcher rc
  (
    sleep "$limit"
    : > "$flag"
    kill -TERM "$pid" 2>/dev/null || exit 0
    sleep 2
    kill -KILL "$pid" 2>/dev/null
  ) &
  watcher=$!
  wait "$pid" 2>/dev/null; rc=$?
  # Command finished: stop the watcher (and the sleep it is running) so it cannot signal a reused PID.
  pkill -P "$watcher" 2>/dev/null; kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
  if [[ -e $flag ]]; then
    rm -f "$flag"
    ((rc == 143)) && return 124
  fi
  return "$rc"
}

self_test() {
  local rc
  runlimit 5 true; rc=$?;  ((rc == 0))  || { echo "FAIL: true rc=$rc" >&2; return 1; }
  runlimit 5 sh -c 'exit 7'; rc=$?; ((rc == 7)) || { echo "FAIL: passthrough rc=$rc" >&2; return 1; }
  runlimit 1 sleep 30; rc=$?; ((rc == 124)) || { echo "FAIL: TERM case rc=$rc" >&2; return 1; }
  runlimit 1 sh -c 'trap "" TERM; while :; do sleep 1; done'; rc=$?
  ((rc == 137)) || { echo "FAIL: KILL case rc=$rc" >&2; return 1; }
  runlimit 2>/dev/null; rc=$?; ((rc != 0)) || { echo "FAIL: no args accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else runlimit "$@"; fi
