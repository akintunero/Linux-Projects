#!/usr/bin/env bash
# Day 20 medium: a cron-safe job (own PATH, absolute paths, log file, lock) tested in a bare environment.
# Temporary files only; nothing is added to your crontab.
set -euo pipefail

work="$(mktemp -d)"

cat > "${work}/job.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
base="$1"                                  # absolute directory handed to us, no reliance on cwd
log="${base}/job.log"
exec 9> "${base}/job.lock"
exec >> "$log" 2>&1                        # from here on everything goes to the log

if ! flock -n 9; then
    echo "skipped: previous run still active"
    exit 0
fi
echo "start"
sleep "${JOB_SECONDS:-0}"
echo "done"
EOF

# Start a long run, then a second one while the first holds the lock.
(cd / && env -i PATH=/usr/bin:/bin JOB_SECONDS=1 bash "${work}/job.sh" "$work") &
sleep 0.4
(cd / && env -i PATH=/usr/bin:/bin bash "${work}/job.sh" "$work")
wait

echo "--- job.log"
cat "${work}/job.log"

rm -rf -- "$work"
