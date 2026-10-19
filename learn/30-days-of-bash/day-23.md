# Day 23: Git from Bash Scripts

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 22](day-22.md)

## Goal

By the end of this lesson you can:

- Query a repository from a script using stable, machine-readable `git` commands.
- Generate release notes from commit history.
- Write a `pre-commit` hook that blocks bad commits.

## Concepts

This lesson assumes you know basic Git (`init`, `add`, `commit`, `branch`). It is about *scripting*
Git: asking it questions and acting on the answers. All examples use a throwaway repository, and a
demo identity set through environment variables, so your own Git configuration is untouched.

### Ask git, don't scrape it

Human output (`git status`, `git branch`, `git log`) changes between versions and is meant for people.
Use plumbing or porcelain forms for scripts:

| Question | Command |
|----------|---------|
| Am I inside a repository? | `git rev-parse --is-inside-work-tree` |
| Current branch (`HEAD` if detached) | `git rev-parse --abbrev-ref HEAD` |
| Number of commits | `git rev-list --count HEAD` |
| Subject of the last commit | `git log -1 --format=%s` |
| Is the tree dirty? | `[[ -n "$(git status --porcelain)" ]]` |
| Any unstaged changes? | `git diff --quiet` (exit 1 if yes) |
| Anything staged? | `git diff --cached --quiet` |
| Changed file names | `git diff --name-only A B` |
| Tracked files | `git ls-files` |
| Latest tag | `git describe --tags --abbrev=0` |
| Where is the repo root? | `git rev-parse --show-toplevel` |

`git -C DIR ...` runs a command as if started in `DIR`, so you rarely need `cd`.

### Formatting history

`git log --format='%h %an %s'` prints your own layout (`%h` short hash, `%an` author, `%s` subject).
A range `v1.0.0..HEAD` means "commits reachable from HEAD but not from the tag": exactly the release
notes. Add `--reverse` for oldest first and `--no-merges` to skip merge commits.

### Commit message conventions

If commit subjects start with `feat:`, `fix:`, `docs:` and so on (Conventional Commits), a script can
group them into sections of a changelog.

### Hooks

A hook is an executable file in `.git/hooks/` named after an event. `pre-commit` runs before a
commit is created; **a non-zero exit blocks the commit**. Hooks are local (not pushed with the
repository), so teams share them through a tracked directory plus `git config core.hooksPath`.

> [!WARNING]
> `git commit --no-verify` skips hooks. A hook is a safety net for honest mistakes, not a security
> boundary. Real secret scanning also belongs in CI.

### Safe habits in scripts

- Never run `git reset --hard`, `git clean -fd` or force-push from a script without an explicit,
  confirmed flag. They destroy work.
- Pass `-q` to silence chatter, and set `GIT_PAGER=cat` (or use `--no-pager`) so output is not piped to
  `less`.
- Check `git status --porcelain` before doing anything that modifies the tree.

## Worked example

Six ways to interrogate a repository. Save as `git.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# git.sh - git from scripts: machine-readable output, no pagers, no prompts
set -euo pipefail

# A private identity for this demo only (nothing is written to your git config).
export GIT_AUTHOR_NAME="Demo User"  GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo User" GIT_COMMITTER_EMAIL="demo@example.com"

git init -q -b main repo
cd repo

echo "--- 1. commit some history"
echo "v1" > app.txt
git add app.txt
git commit -q -m "feat: add app"
echo "v2" > app.txt
git commit -q -am "fix: correct version"
git tag v1.0.0
echo "extra" > notes.txt
git add notes.txt
git commit -q -m "feat: add notes"
git commit -q --allow-empty -m "fix: handle empty notes"

echo "--- 2. script-friendly state queries"
echo "branch:  $(git rev-parse --abbrev-ref HEAD)"
echo "commits: $(git rev-list --count HEAD)"
echo "latest:  $(git log -1 --format=%s)"
echo "tracked: $(git ls-files | tr '\n' ' ')"

echo "--- 3. is the working tree clean? (--porcelain output is stable across versions)"
is_dirty() { [[ -n "$(git status --porcelain)" ]]; }
if is_dirty; then echo "dirty"; else echo "clean"; fi
echo "scratch" > scratch.tmp
echo "app v3" >> app.txt
git status --porcelain
if is_dirty; then echo "dirty"; else echo "clean"; fi

echo "--- 4. changes since the last tag, as a changelog"
git log v1.0.0..HEAD --format='- %s'

echo "--- 5. files changed between two commits (here: what the notes commit added)"
git diff --name-only HEAD~2 HEAD~1

echo "--- 6. run git elsewhere without cd, and check exit codes"
git -C . rev-parse --is-inside-work-tree
if git diff --quiet; then echo "no unstaged changes"; else echo "unstaged changes (exit 1 from --quiet)"; fi
```

**Expected output**

```text
--- 1. commit some history
--- 2. script-friendly state queries
branch:  main
commits: 4
latest:  fix: handle empty notes
tracked: app.txt notes.txt
--- 3. is the working tree clean? (--porcelain output is stable across versions)
clean
 M app.txt
?? scratch.tmp
dirty
--- 4. changes since the last tag, as a changelog
- fix: handle empty notes
- feat: add notes
--- 5. files changed between two commits (here: what the notes commit added)
notes.txt
--- 6. run git elsewhere without cd, and check exit codes
true
unstaged changes (exit 1 from --quiet)
```

Section 3 shows `--porcelain` output: two characters of status, a space, then the path (`M` modified,
`??` untracked). The same format has been stable for many Git versions.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `[ $(git status --porcelain) ]` | Several lines expand to several words: `too many arguments` | `[[ -n "$(git status --porcelain)" ]]` |
| `git branch \| grep '*' \| awk ...` | Breaks on a detached HEAD and on future format changes | `git rev-parse --abbrev-ref HEAD` |
| `git log \| grep -c commit` | Also counts messages containing the word | `git rev-list --count HEAD` |
| `git status \| grep "nothing to commit"` | Depends on the language and wording | `--porcelain` |
| Relying on global git config | The script behaves differently on each machine | Set `GIT_AUTHOR_*`/`-c user.name=` explicitly in automation |
| Committing from a script with no check | Commits half-finished work | Check the tree first, quote messages |
| `git add .` in a script | Stages stray files (logs, `.env`) | Add named paths |
| Hook not executable | Git silently ignores it | `chmod +x .git/hooks/pre-commit` |

## Exercises

### Easy: repository summary

Write `repo_summary [DIR]` that prints branch, last commit subject, number of commits, number of
changed files, number of untracked files, and `clean`/`dirty`. In a directory that is not a
repository it should print a message and return 1. Demonstrate both cases in a throwaway repo.

**Acceptance criteria**

- A repo with one commit, one modified file and one untracked file reports `changed: 1 file(s)`,
  `untracked: 1 file(s)` and `state: dirty`.
- Outside a repo: message on stderr and exit status 1.
- Uses `git -C`, not `cd`, and no scraping of `git status` text.

### Medium: release notes

Create a repo with two commits, tag `v1.0.0`, add five more commits with `feat:`, `fix:` and
`docs:` subjects (and one `chore:`). Print release notes since the latest tag grouped into
`Features`, `Fixes` and `Documentation` with the prefix removed, and count the ungrouped commits.

**Acceptance criteria**

- Features list `add search` and `add export` in commit order.
- Empty sections are not printed.
- `Other: 1 commit(s)` for the `chore:` commit.

### Hard: a `pre-commit` hook

Install a hook that rejects staged changes with trailing whitespace or a line such as
`password = ...`. Then try four commits: clean, trailing space, password, and fixed. Print which were
committed or rejected and the final log.

**Acceptance criteria**

- Rejected commits print the reason on stderr and are not recorded.
- The log shows only `add config` and `add port`.
- The hook inspects only *added* lines (`git diff --cached -U0`).

### Break it

This script has **three bugs**: a syntax error from the test, a wrong branch name and a wrong
commit count. Save as `break-it.sh`, run it in an empty directory, and fix it so it prints
`working tree is dirty`, `branch: HEAD` and `commits: 2`.

```bash
#!/usr/bin/env bash
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"
git init -q -b main repo
cd repo

echo a > a.txt
echo b > b.txt
if [ $(git status --porcelain) ]; then
    echo "working tree is dirty"
fi

git add -A
git commit -q -m "first"
git commit -q --allow-empty -m "fix commit message typo"
git checkout -q --detach

echo "branch: $(git branch | grep '*' | awk '{print $2}')"
echo "commits: $(git log | grep -c commit)"
```

**Expected output**

```text
break-it.sh: line 9: [: too many arguments
branch: (HEAD
commits: 3
```

<details>
<summary>Hint</summary>

There are two untracked files, so `git status --porcelain` prints two lines. The detached HEAD makes
the scraped branch name wrong, and one commit message contains the word "commit".

</details>

## Solutions

<details>
<summary>Easy</summary>

`grep -c` prints a count but exits 1 when it is 0, so it is followed by `|| true` under `set -e`.

```bash
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
```

**Expected output**

```text
branch:    main
last:      Add a.txt
commits:   1
changed:   1 file(s)
untracked: 1 file(s)
state:     dirty
not a git repository
outside a repo -> exit 1
```

</details>

<details>
<summary>Medium</summary>

`git describe --tags --abbrev=0` finds the nearest tag. `sed -E "s/^feat: /- /"` removes the prefix
and adds the bullet in one step.

```bash
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
```

**Expected output**

```text
Release notes since v1.0.0

Features
- add search
- add export

Fixes
- crash on empty input

Documentation
- update usage

Other: 1 commit(s)
```

</details>

<details>
<summary>Hard</summary>

The hook filters the diff to added lines (`^\+[^+]`, excluding the `+++` headers), then greps those.
Because the hook is a separate file written with a quoted here-doc, none of its `$` signs are expanded
by the outer script.

```bash
#!/usr/bin/env bash
# Day 23 hard: install a pre-commit hook that blocks trailing whitespace and obvious secrets.
# Works only inside a throwaway repository.
set -euo pipefail
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"

work="$(mktemp -d)"
git init -q -b main "${work}/repo"
cd "${work}/repo"

cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
# Reject commits that add trailing whitespace or a line like  password=...
set -euo pipefail
status=0
added="$(git diff --cached -U0 --no-color | grep -E '^\+[^+]' || true)"

if grep -nE '^\+.*[[:space:]]+$' <<< "$added" >/dev/null; then
    echo "pre-commit: trailing whitespace in staged changes" >&2
    status=1
fi
if grep -niE '^\+.*(password|secret|api_key)[[:space:]]*=' <<< "$added" >/dev/null; then
    echo "pre-commit: possible secret in staged changes" >&2
    status=1
fi
exit "$status"
EOF
chmod +x .git/hooks/pre-commit

try_commit() {                                 # try_commit MESSAGE
    if git commit -q -m "$1"; then
        echo "committed: $1"
    else
        echo "REJECTED:  $1"
    fi
}

printf 'name = shop\n' > app.conf
git add app.conf
try_commit "add config"

printf 'name = shop\nport = 8080 \n' > app.conf       # note the trailing space
git add app.conf
try_commit "add port (trailing space)"

printf 'name = shop\nport = 8080\npassword = hunter2\n' > app.conf
git add app.conf
try_commit "add password"

printf 'name = shop\nport = 8080\n' > app.conf        # fixed
git add app.conf
try_commit "add port"

echo "--- commits that made it in"
git log --format='  %s' --reverse

cd / && rm -rf -- "$work"
```

**Expected output**

```text
committed: add config
pre-commit: trailing whitespace in staged changes
REJECTED:  add port (trailing space)
pre-commit: possible secret in staged changes
REJECTED:  add password
committed: add port
--- commits that made it in
  add config
  add port
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `[ $(git status --porcelain) ]` splits the two status lines into four words. Bug 2: scraping
`git branch` yields `(HEAD` on a detached head; ask `git rev-parse --abbrev-ref HEAD`. Bug 3:
`git log | grep -c commit` also matched the message `fix commit message typo`; use
`git rev-list --count`.

```bash
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
```

**Expected output**

```text
working tree is dirty
branch: HEAD
commits: 2
```

</details>

Solution files live in [`solutions/day-23/`](solutions/day-23/).

## Self-check

1. Which flag gives stable, parseable output from `git status`?
2. How do you check whether there are unstaged changes in a script?
3. What does `git log v1.0.0..HEAD` select?
4. What makes a `pre-commit` hook block a commit?
5. Why is `git add .` risky in automation?

<details>
<summary>Answers</summary>

1. `--porcelain`.
2. `git diff --quiet` (non-zero exit means there are changes).
3. Commits reachable from `HEAD` but not from the tag `v1.0.0`.
4. The hook is executable and exits with a non-zero status.
5. It stages everything in the tree, including files you did not mean to commit.

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `git -C DIR cmd` | Run in another directory |
| `git rev-parse --abbrev-ref HEAD` | Branch name |
| `git rev-list --count HEAD` | Commit count |
| `git status --porcelain` | Stable status |
| `git diff --quiet` / `--cached --quiet` | Any unstaged / staged changes? |
| `git log A..B --format=%s` | Subjects in a range |
| `git describe --tags --abbrev=0` | Latest tag |
| `git diff --name-only A B` | Changed files |
| `.git/hooks/pre-commit` (executable) | Block bad commits |

## Further reading

- [Git book: Customizing Git, hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks):
  every hook, when it runs, and how to write one.
- [git-status manual: porcelain format](https://git-scm.com/docs/git-status#_porcelain_format_version_1):
  the exact meaning of the two status characters.
- [git-rev-parse manual](https://git-scm.com/docs/git-rev-parse): the Swiss-army knife for asking
  scripts' questions about a repo.
- [Conventional Commits](https://www.conventionalcommits.org/): the commit message convention used for
  generating changelogs.

**Next:** [Day 24](day-24.md)
