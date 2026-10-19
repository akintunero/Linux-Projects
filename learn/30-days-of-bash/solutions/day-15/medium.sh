#!/usr/bin/env bash
# Day 15 medium: a temp directory that is always cleaned up, even when the job fails.
set -euo pipefail

marker="$(mktemp -u)"          # name of a marker file the job will use to tell us its temp dir

job() {
    # Not "local": an EXIT trap runs after the function has returned, when locals are gone.
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' EXIT          # single quotes: expand when the trap runs
    echo "$work" > "$marker"
    echo "job: working in a temp dir"
    echo "payload" > "$work/data.txt"
    return 3                                # simulate a failure
}

status=0
( job ) || status=$?
work_dir="$(< "$marker")"

echo "job exit status: ${status}"
if [[ -e $work_dir ]]; then
    echo "temp dir LEFT BEHIND"
else
    echo "temp dir was removed"
fi
rm -f -- "$marker"
