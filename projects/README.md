# Projects

Complete scripts that are small enough to read in one sitting and good enough to copy habits from. Each
folder has a README with usage, how it works, and exercises.

| Project | Level | You will learn |
|---------|-------|----------------|
| [todo-list](todo-list/README.md) | Beginner | `case`, functions, validation, safe file edits, backups |
| [disk-space-usage](disk-space-usage/README.md) | Beginner → Intermediate | `du`/`find`/`sort`, option parsing, portability |
| [user-management](user-management/README.md) | Intermediate | `useradd`/`usermod`, dry-run pattern, safe password handling |
| [devops-scripts](devops-scripts/README.md) | Intermediate → Advanced | `curl`+`jq`, caching, Docker CLI, testing with stubs |

All of them source [`../lib/common.sh`](../lib/common.sh) for logging, validation helpers and colour handling.

## How to study a project

1. **Run it** and try every option, including wrong ones.
2. **Read the tests** in [`../tests/`](../tests/): they are the specification.
3. **Break it**: change a line, run `make test`, see which test notices.
4. **Do the exercises** in its README. Write the test first.

## Conventions every script follows

- `set -euo pipefail`, quoted variables, `[[ ]]`, and `local` in functions.
- `--help` works with no dependencies installed.
- Errors go to stderr; non-zero exit codes are meaningful (`2` invalid input, `77` needs root).
- Anything that changes the system supports `--dry-run`.
- Passwords and tokens are never command-line arguments.
