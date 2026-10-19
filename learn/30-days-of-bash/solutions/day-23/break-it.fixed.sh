#!/usr/bin/env bash
# Fixed: test with [[ -n ... ]], ask git for the branch and the count instead of scraping.
set -euo pipefail
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"
git init -q -b main repo
cd repo

echo a > a.txt
echo b > b.txt
if [[ -n "$(git status --porcelain)" ]]; then
    echo "working tree is dirty"
fi

git add -A
git commit -q -m "first"
git commit -q --allow-empty -m "fix commit message typo"
git checkout -q --detach

echo "branch: $(git rev-parse --abbrev-ref HEAD)"
echo "commits: $(git rev-list --count HEAD)"
