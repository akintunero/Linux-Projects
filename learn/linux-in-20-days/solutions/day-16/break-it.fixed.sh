#!/usr/bin/env bash
# Day 16 - Break it, fixed. Bugs were:
#   1. `[ -f lock ] ... touch lock` checks and creates in two steps: two jobs starting together can both
#      pass the check (race). flock takes the lock atomically.
#   2. If the job is killed, `rm $lock` never runs and the stale file blocks every later run for ever.
#      A flock is released by the kernel when the process dies, whatever the reason.
#   3. `lock=job.lock` is relative to the current directory; cron starts jobs in $HOME, so each
#      directory gets its own lock and the protection is lost. Use one absolute path.
# NEEDS-TOOL: flock (exits 77 if missing). Self-test: break-it.fixed.sh --self-test
set -uo pipefail

run_job() {
  local lock=${LOCK:-${XDG_RUNTIME_DIR:-/tmp}/linux20-job.lock}
  exec 9> "$lock"
  if ! flock -n 9; then echo "already running, skipping"; return 0; fi
  echo "start"
  sleep "${WORK_SECONDS:-5}"
  echo "done"
}

if [[ ${1:-} == --self-test ]]; then
  command -v flock >/dev/null || { echo "flock missing" >&2; exit 77; }
  w=$(mktemp -d); trap 'rm -rf "$w"' EXIT
  export LOCK=$w/job.lock
  me=$(readlink -f "${BASH_SOURCE[0]}")
  WORK_SECONDS=2 bash "$me" > "$w/a" & a=$!
  sleep 0.5
  (cd / && WORK_SECONDS=2 bash "$me" > "$w/b")          # started from a different directory
  wait "$a"
  grep -qx 'done' "$w/a" && grep -qx 'already running, skipping' "$w/b" || { echo "FAIL: overlap" >&2; exit 1; }
  WORK_SECONDS=30 bash "$me" > "$w/c" & c=$!
  sleep 0.5; kill -9 "$c"; wait "$c" 2>/dev/null; pkill -f 'sleep 30' 2>/dev/null; sleep 0.3
  WORK_SECONDS=0 bash "$me" > "$w/d"
  grep -qx 'done' "$w/d" || { echo "FAIL: stale lock" >&2; exit 1; }
  echo PASS >&2
else
  run_job
fi
