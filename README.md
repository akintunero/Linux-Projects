# Linux-Projects

[![CI](https://github.com/akintunero/Linux-Projects/actions/workflows/ci.yml/badge.svg)](https://github.com/akintunero/Linux-Projects/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Linux and Bash lessons with exercises and solutions, a few small scripts to read and extend, and a test
suite for those scripts. The lessons are written to be typed and run, not just read.

## Courses

| Course | What it covers | Format |
|--------|----------------|--------|
| [Linux in 20 days](learn/linux-in-20-days/README.md) | Using Linux: files, permissions, processes, networking, services | One lesson per day, with exercises and solutions |
| [30 days of Bash](learn/30-days-of-bash/README.md) | Shell scripting, from a first script to a final project | One lesson per day, with exercises and solutions |
| [12-step Linux path](learn/linux-path/README.md) | Administration: users, networking, security, storage, backup, automation, containers, plus a capstone | Tasks with commands, verification and undo steps |

If you are new to the terminal, set up a lab first ([setup/README.md](setup/README.md)), then follow Linux in
20 days. If you already use Linux, start with 30 days of Bash or the 12-step path.

Each day lesson has the same sections: goal, concepts, a worked example, common mistakes, exercises (easy,
medium, hard), a "break it" debugging exercise, solutions, a self-check and a cheat sheet. The format is
described in the [style guide](docs/style-guide.md). Commands that can lock you out or destroy data have a
warning before them and an undo step after them. Anything that could not be run while writing the lessons is
marked as typical output.

## Projects

Small scripts, each with a README, tests and exercises. See [projects/README.md](projects/README.md).

- [todo-list](projects/todo-list/README.md): input validation, backups and search.
- [disk-space-usage](projects/disk-space-usage/README.md): `du`, `find` and `sort`, written to be portable.
- [user-management](projects/user-management/README.md): users and groups from one CLI, with `--dry-run`.
- [devops-scripts](projects/devops-scripts/README.md): a REST API client and a Docker manager.

They share the helpers in [lib/common.sh](lib/common.sh). The tests are in [tests/](tests/).

## Getting started

```bash
git clone https://github.com/akintunero/Linux-Projects.git
cd Linux-Projects
projects/todo-list/todo.sh add "Learn Linux"
projects/todo-list/todo.sh list
```

To run the checks (ShellCheck, shfmt, syntax check and the Bats tests):

```bash
make setup   # Debian/Ubuntu: installs bats, shellcheck, shfmt and jq
make check
```

Requirements: Bash 4.4 or newer (developed on Bash 5; the Bash 3.2 that ships with macOS is too old, so use
`brew install bash`), Linux, WSL or macOS. The API client needs `curl` and `jq`, and the container manager
needs `docker`. A [dev container](.devcontainer/devcontainer.json) with everything installed is available.

## Contributing

Corrections, new exercises and better explanations are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[style guide](docs/style-guide.md). If a lesson confused you or a command failed, open a
[lesson feedback issue](https://github.com/akintunero/Linux-Projects/issues/new/choose). Report security
problems as described in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE).
