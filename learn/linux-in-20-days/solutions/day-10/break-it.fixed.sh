#!/usr/bin/env bash
# Day 10 - Break it, fixed. Bugs were:
#   1. `pgrep sleep` finds the sleep INSIDE the worker (or any other sleep on the box), not the worker;
#      use $! right after starting the job.
#   2. `kill -9` cannot be caught, so the trap never runs and the lock file stays. Send TERM first.
#   3. `$?` after `kill` is kill's own status, not the worker's. Use `wait PID` to collect it.
# Safe: temporary directory only.
set -uo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work" || exit 1

cat > worker.sh <<'EOS'
#!/usr/bin/env bash
touch worker.lock
trap 'rm -f worker.lock; exit 3' TERM
while :; do sleep 1; done
EOS

bash worker.sh &
pid=$!
sleep 0.5
kill -TERM "$pid"
wait "$pid"; rc=$?
echo "worker exited with $rc"
[[ ! -e worker.lock ]] || { echo "FAIL: lock file left behind" >&2; exit 1; }
[[ $rc -eq 3 ]]        || { echo "FAIL: rc=$rc" >&2; exit 1; }
echo PASS >&2
