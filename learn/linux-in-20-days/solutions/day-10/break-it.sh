#!/usr/bin/env bash
# Day 10 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: start a worker that removes its lock file when it is asked to stop, stop it politely,
# and report the worker's exit status (expected: 3, the status the worker uses for "stopped").
cat > worker.sh <<'EOF'
#!/usr/bin/env bash
touch worker.lock
trap 'rm -f worker.lock; exit 3' TERM
while :; do sleep 1; done
EOF

bash worker.sh &
sleep 0.5
pid=$(pgrep sleep)
kill -9 $pid
echo "worker exited with $?"
ls worker.lock 2>/dev/null && echo "BUG: lock file left behind"
