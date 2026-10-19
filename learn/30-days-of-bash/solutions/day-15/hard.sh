#!/usr/bin/env bash
# Day 15 hard: a job with a lock and a temp dir that survives signals.
# The script writes a child job, sends that job SIGTERM, and checks the cleanup.
# Temporary files only.
set -euo pipefail

root="$(mktemp -d)"
cat > "${root}/job.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
lock="$1/job.lock"
work="$(mktemp -d "$1/work.XXXXXX")"

cleanup() {
    rm -rf -- "$work"
    rmdir -- "$lock" 2>/dev/null || true
}
trap cleanup EXIT                       # always runs
trap 'echo "job: caught SIGTERM"; exit 143' TERM
trap 'echo "job: caught SIGINT"; exit 130' INT

if ! mkdir -- "$lock" 2>/dev/null; then # mkdir is atomic: only one process wins
    echo "job: already running" >&2
    exit 75
fi
echo "job: lock taken, working"
kill -TERM $$                           # simulate someone stopping the job
echo "job: not reached"
EOF

status=0
bash "${root}/job.sh" "$root" || status=$?
echo "job exit status: ${status} (143 = terminated by SIGTERM)"

if [[ -e ${root}/job.lock ]]; then
    echo "lock LEFT BEHIND"
else
    echo "lock released"
fi
leftover="$(find "$root" -maxdepth 1 -name 'work.*' | wc -l)"
echo "temp work dirs left: ${leftover}"

echo "--- second instance while the lock is held"
mkdir "${root}/job.lock"
status=0
bash "${root}/job.sh" "$root" || status=$?
echo "second instance exit status: ${status}"

rm -rf -- "$root"
