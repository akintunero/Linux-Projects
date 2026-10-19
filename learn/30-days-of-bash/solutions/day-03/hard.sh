#!/usr/bin/env bash
# Day 03 hard: build a release tag and a backup file name under strict mode.
set -euo pipefail

major=2
minor=7
patch=9

patch=$(( patch + 1 ))               # not ((patch++)): it returns 1 when the old value is 0
tag="v${major}.${minor}.${patch}"
echo "Next tag: ${tag}"

host="$(hostname -s)"
stamp="$(date +%F)"
backup="backup-${host}-${stamp}.tar.gz"
if [[ $backup == backup-*-????-??-??.tar.gz ]]; then
    echo "Backup name has the expected shape"
fi

# ${VAR:?message} aborts with a message when VAR is unset or empty.
( : "${DEPLOY_DIR:?DEPLOY_DIR must be set}" ) 2>&1 || echo "refused to continue without DEPLOY_DIR"
