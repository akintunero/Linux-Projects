#!/usr/bin/env bash
# Day 16 - Medium: stop a scheduled job from overlapping itself with flock, and show that the lock
# disappears when the holder dies (no stale lock file problem).
# NEEDS-TOOL: flock (util-linux; exits 77 if missing). Safe: temporary directory only.
set -uo pipefail
command -v flock >/dev/null || { echo "flock missing" >&2; exit 77; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work" || exit 1

cat > job.sh <<'EOF'
#!/usr/bin/env bash
exec 9> "${LOCK:?}"                       # open (and create) the lock file on file descriptor 9
if ! flock -n 9; then echo "already running, skipping"; exit 0; fi
echo "start"; sleep "${WORK_SECONDS:-2}"; echo "done"
EOF
export LOCK="$work/job.lock"

# 1. Two overlapping runs: the second must skip.
bash job.sh > first.out & first=$!
sleep 0.5
bash job.sh > second.out
wait "$first"
cat first.out second.out
grep -qx 'done' first.out                     || { echo "FAIL: first run did not finish" >&2; exit 1; }
grep -qx 'already running, skipping' second.out || { echo "FAIL: overlap not prevented" >&2; exit 1; }

# 2. Kill a run in the middle: the next run must NOT be blocked (the kernel drops the lock).
WORK_SECONDS=30 bash job.sh > killed.out & victim=$!
sleep 0.5
kill -9 "$victim"; wait "$victim" 2>/dev/null
pkill -f "sleep 30" 2>/dev/null || true       # the orphaned sleep may still hold the descriptor
sleep 0.3
WORK_SECONDS=0 bash job.sh > third.out
cat third.out
grep -qx 'done' third.out || { echo "FAIL: stale lock blocked the next run" >&2; exit 1; }
echo PASS >&2
