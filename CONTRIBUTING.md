# Contributing

Thank you for helping people learn Linux. The most valuable contributions are **fixing a lesson that
confused or failed you**, adding exercises and solutions, and improving tests.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Report security problems
privately as described in [SECURITY.md](SECURITY.md).

## Quick start

```bash
git clone https://github.com/<you>/Linux-Projects.git
cd Linux-Projects
git checkout -b fix/short-description

make setup    # Debian/Ubuntu/WSL: installs bats, shellcheck, shfmt, jq
make check    # lint + format check + syntax + tests (what CI runs)
```

No Linux machine? Use the [dev container](setup/README.md): everything is preinstalled.

Optional: `pip install pre-commit && pre-commit install` runs the checks on every commit.

## Where things live

| You want to change | Look in | Follow |
|--------------------|---------|--------|
| A lesson | `learn/<course>/` | [docs/style-guide.md](docs/style-guide.md) |
| A project script | `projects/<name>/` | the script rules below |
| Tests | `tests/*.bats` | [Bats docs](https://bats-core.readthedocs.io/) |
| CI, tooling | `.github/`, `Makefile` | keep `make check` and CI in sync |

## Script rules

1. `#!/usr/bin/env bash`, then `set -euo pipefail`. The file is executable and has LF line endings.
2. Quote every expansion (`"$var"`), use `[[ ]]`, `local` in functions, `read -r`, `printf` over `echo -e`.
3. Source `lib/common.sh` for `msg`/`ok`/`warn`/`err`/`die` instead of re-implementing them.
4. Errors go to stderr and exit non-zero (`2` invalid input, `77` needs root, `127` missing dependency).
5. `--help` must work without any optional dependency installed.
6. Anything that changes the system supports `--dry-run`.
7. Never accept passwords or tokens as command-line arguments. Read them from stdin or the environment.
8. Never use `eval` on user input. Build commands as arrays.
9. It passes `shellcheck -x` and `shfmt -i 4 -ci` with no warnings.
10. It has tests. Write the failing test first.

## Writing tests

Tests live in `tests/<script-name>.bats` and `load test_helper`, which gives you a scratch directory
(`make_workdir`) and a way to fake commands (`make_stub NAME 'body'`).

```bash
@test "remove rejects zero" {
    run "$TODO" remove 0
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
}
```

- Tests must be **safe anywhere**: no root, no internet, no touching real users, disks or containers.
  Use `--dry-run`, local servers on `127.0.0.1`, or stubs.
- Test failures and edge cases, not only the happy path.
- Run one file with `bats tests/todo.bats`, or one test with `bats tests/todo.bats --filter "remove"`.

## Writing or editing lessons

Read the [style guide](docs/style-guide.md). The short version:

- Every code block is fenced and tagged (`bash`, `text`, `ini`).
- Show the **expected output**, and only paste output you actually saw.
- Risky command? Put a warning before it and an **undo** step after it.
- Prefer official documentation links, each with a one-line note about what the reader will find.
- Exercises have acceptance criteria; solutions are runnable scripts that pass ShellCheck.

## Pull requests

1. Keep a PR to one topic. Small PRs get reviewed faster.
2. `make check` passes. The PR template has the checklist.
3. Describe **why**, not only what.
4. Be ready to iterate. Review is about the learner's experience, not about you.

Commit messages: short imperative summary (`Fix remove for out-of-range index`), blank line, details
if needed.

## Reporting problems

- **A script or lesson is wrong:** open a *Bug report* or *Lesson feedback* issue and include the exact command
  and output.
- **A security issue:** see [SECURITY.md](SECURITY.md); do not open a public issue.

## Credits

Add yourself to [CONTRIBUTORS.md](CONTRIBUTORS.md) in your first pull request.
