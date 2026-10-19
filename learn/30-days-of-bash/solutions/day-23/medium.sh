#!/usr/bin/env bash
# Day 23 medium: release notes since the latest tag, grouped by conventional-commit prefix.
# Uses a throwaway repository.
set -euo pipefail
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"

work="$(mktemp -d)"
git init -q -b main "${work}/repo"
cd "${work}/repo"
for msg in "feat: initial release" "fix: typo in readme"; do
    git commit -q --allow-empty -m "$msg"
done
git tag v1.0.0
for msg in "feat: add search" "fix: crash on empty input" "docs: update usage" "feat: add export" "chore: bump deps"; do
    git commit -q --allow-empty -m "$msg"
done

last_tag="$(git describe --tags --abbrev=0)"
echo "Release notes since ${last_tag}"

section() {                                    # section TITLE PREFIX
    local lines
    lines="$(git log "${last_tag}..HEAD" --format=%s --reverse | grep -E "^$2: " | sed -E "s/^$2: /- /" || true)"
    if [[ -n $lines ]]; then
        echo
        echo "$1"
        echo "$lines"
    fi
}

section "Features" feat
section "Fixes" fix
section "Documentation" docs
echo
echo "Other: $(git log "${last_tag}..HEAD" --format=%s | grep -vcE '^(feat|fix|docs): ' || true) commit(s)"

cd / && rm -rf -- "$work"
