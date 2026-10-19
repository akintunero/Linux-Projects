#!/usr/bin/env bash
# Day 23 easy: a one-screen repository summary. Uses a throwaway repository.
set -euo pipefail
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"

repo_summary() {
    local dir="${1:-.}"
    git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "not a git repository" >&2
        return 1
    }
    local untracked changed
    untracked="$(git -C "$dir" status --porcelain | grep -c '^??' || true)"
    changed="$(git -C "$dir" status --porcelain | grep -vc '^??' || true)"
    echo "branch:    $(git -C "$dir" rev-parse --abbrev-ref HEAD)"
    echo "last:      $(git -C "$dir" log -1 --format=%s)"
    echo "commits:   $(git -C "$dir" rev-list --count HEAD)"
    echo "changed:   ${changed} file(s)"
    echo "untracked: ${untracked} file(s)"
    if [[ $changed -eq 0 && $untracked -eq 0 ]]; then echo "state:     clean"; else echo "state:     dirty"; fi
}

work="$(mktemp -d)"
git init -q -b main "${work}/repo"
echo one > "${work}/repo/a.txt"
git -C "${work}/repo" add a.txt
git -C "${work}/repo" commit -q -m "Add a.txt"
echo two >> "${work}/repo/a.txt"
echo scratch > "${work}/repo/b.tmp"

repo_summary "${work}/repo"
status=0
repo_summary "$work" || status=$?
echo "outside a repo -> exit ${status}"

rm -rf -- "$work"
