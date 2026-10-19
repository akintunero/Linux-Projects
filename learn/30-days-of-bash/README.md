# 30 Days of Bash

Welcome to **30 Days of Bash** — a hands-on, practical course designed to take you from writing your first command line to authoring resilient, production-ready automation scripts and administrative tools.

Every lesson is structured around real-world patterns, featuring:

- **Core Concepts:** Clear explanations without unnecessary jargon.
- **Worked Examples:** Fully executed code with verified, reproducible outputs.
- **Common Mistakes:** Tables analyzing gotchas, subtle bugs, and how to avoid them.
- **Graded Exercises:** Easy, Medium, and Hard exercises with verifiable acceptance criteria.
- **Break It:** Debugging exercises where you find and fix realistic production bugs.
- **Self-Checks & Cheat Sheets:** Quick reviews to consolidate retention.

---

## How to Use This Course

### 1. Dedicated Practice Directory

Always practice in an isolated directory so you never risk overwriting personal or system files:

```bash
mkdir -p ~/bash-lab
cd ~/bash-lab
```

All exercises and worked examples are designed to run safely inside this sandbox using fixtures and temporary files.

### 2. Tools Needed

Ensure you have the standard Linux command-line utilities installed (available by default on Ubuntu/Debian or WSL):

- **Bash 4.4+** (`bash --version`)
- **Core utilities:** `coreutils`, `grep`, `sed`, `gawk`, `curl`, `tar`, `findutils`
- **Recommended linters and test tools:**
  - `shellcheck` (static analysis for shell scripts)
  - `shfmt` (POSIX/Bash shell script formatter)
  - `jq` (command-line JSON processor)
  - `bats` (Bash Automated Testing System)

In Ubuntu/Debian or WSL:

```bash
sudo apt update && sudo apt install -y bash shellcheck shfmt jq bats curl
```

### 3. Solutions Layout

Official reference solutions for all exercises and debugging tasks live under the [`solutions/`](solutions/) directory:

```text
solutions/
├── day-01/
│   ├── easy.sh
│   ├── medium.sh
│   ├── hard.sh
│   └── break-it.fixed.sh
├── ...
└── day-30/
    ├── easy.sh
    ├── medium.sh
    ├── hard.sh
    └── break-it.fixed.sh
```

Try solving each challenge yourself first in `~/bash-lab` before checking the solution.

---

## Progress Checklist & Syllabus

Track your daily journey across all 30 days:

| Status | Day | Topic | Time | Core Skills |
|:------:|:---|:------|:----:|:------------|
| [ ] | [Day 01](day-01.md) | Introduction to Bash and Setting Up | ~45 min | Shell discovery, PATH, shebang lines, file execution permissions |
| [ ] | [Day 02](day-02.md) | Files, Navigation and Globbing | ~50 min | Safe directory traversal, standard globbing (`*`, `?`, `[]`), dotfiles |
| [ ] | [Day 03](day-03.md) | Variables, Quoting and Strict Mode | ~50 min | Variable assignment, parameter expansions, double vs single quotes, strict mode (`set -euo pipefail`) |
| [ ] | [Day 04](day-04.md) | Decisions, Tests and Exit Codes | ~50 min | Conditional tests (`[[ ... ]]`), integer/string comparisons, exit statuses (`$?`) |
| [ ] | [Day 05](day-05.md) | Loops and Safe Iteration | ~55 min | `for`, `while`, and `until` loops, safe file iteration without word splitting |
| [ ] | [Day 06](day-06.md) | Functions and Return Codes | ~55 min | Function definitions, local scoping (`local`), positional arguments, return codes |
| [ ] | [Day 07](day-07.md) | Writing a Real Script | ~60 min | Script layout, headers, argument validation, end-to-end utility workflow |
| [ ] | [Day 08](day-08.md) | Redirection, Pipes and Here-Documents | ~55 min | File descriptors (0, 1, 2), pipeline streams, here-documents (`<<EOF`), here-strings (`<<<`) |
| [ ] | [Day 09](day-09.md) | Arrays | ~55 min | Indexed and associative arrays, array slicing, length, iteration with `"${arr[@]}"` |
| [ ] | [Day 10](day-10.md) | Parameter Expansion and String Handling | ~55 min | Substring extraction, pattern replacement (`${var//pattern/repl}`), prefix/suffix trimming |
| [ ] | [Day 11](day-11.md) | Editing Streams with `sed` | ~55 min | Non-interactive stream editing, regex substitutions, delimiter selection, address ranges |
| [ ] | [Day 12](day-12.md) | Reports with `awk` | ~60 min | Field-based text processing, pattern-action pairs, custom delimiters (`-F`), aggregation |
| [ ] | [Day 13](day-13.md) | File Permissions | ~50 min | Octal/symbolic permissions (`chmod`), ownership (`chown`), `umask`, setuid/setgid security |
| [ ] | [Day 14](day-14.md) | Debugging Scripts | ~55 min | Tracing (`set -x`), syntax verification (`bash -n`), trapping errors, verbose diagnostics |
| [ ] | [Day 15](day-15.md) | Error Handling, Exit Codes and `trap` | ~60 min | Exit traps (`trap ... EXIT`), cleanup handlers, standard termination signal handling |
| [ ] | [Day 16](day-16.md) | Command-Line Arguments and `getopts` | ~60 min | POSIX flag parsing with `getopts`, required option arguments, flag validation |
| [ ] | [Day 17](day-17.md) | Automating Bulk Work with `find`, `xargs` | ~60 min | Null-delimited processing (`find -print0 \| xargs -0`), safe file batching, process substitution |
| [ ] | [Day 18](day-18.md) | Environment Variables, `PATH` and Configuration | ~55 min | Environment inheritance, `export`, configuration loading (`.env`), directory precedence |
| [ ] | [Day 19](day-19.md) | Aliases, Functions and Shell Customisation | ~45 min | Shell startup files (`.bashrc`, `.bash_profile`), persistent helpers, alias limitations |
| [ ] | [Day 20](day-20.md) | Scheduling with `cron` | ~60 min | Crontab syntax (5-field schedule), logging cron execution, environment gotchas in cron |
| [ ] | [Day 21](day-21.md) | Regular Expressions | ~60 min | POSIX BRE vs ERE, regex matching inside Bash `[[ $var =~ $regex ]]`, capture groups |
| [ ] | [Day 22](day-22.md) | Networking Basics in Bash | ~60 min | HTTP requests with `curl`, socket checks, response headers, status code parsing |
| [ ] | [Day 23](day-23.md) | Git from Bash Scripts | ~60 min | Plumbing commands, parseable Git output, repo status assertions, porcelain automation |
| [ ] | [Day 24](day-24.md) | Interactive Scripts: `read`, `select` and Menus | ~55 min | Interactive input with `read`, silent inputs, timeouts, terminal menus via `select` |
| [ ] | [Day 25](day-25.md) | Reusable, Testable Scripts | ~60 min | Modular library sourcing, automated unit testing with Bats, deterministic tests |
| [ ] | [Day 26](day-26.md) | JSON in Bash with `jq` | ~60 min | Querying JSON structures, filters, formatting output (TSV/CSV), safe JSON construction |
| [ ] | [Day 27](day-27.md) | Running Other Programs, Jobs and Timeouts | ~60 min | Job control (`&`, `wait`), subprocess management, timeout guards with `timeout` |
| [ ] | [Day 28](day-28.md) | Scripting for System Administration | ~60 min | Read-only metrics from `/proc`, POSIX disk checks (`df -P`), severity rollup models |
| [ ] | [Day 29](day-29.md) | Text Pipelines with `grep`, `cut`, `sort` and Friends | ~60 min | Log file aggregation pipelines, frequency counting (`sort \| uniq -c \| sort -rn`), join |
| [ ] | [Day 30](day-30.md) | Capstone Project: System-Admin Dashboard | ~90 min | Full production CLI dashboard (`sysdash`), live vs fixture modes, 100-point rubric |

---

## Further Resources

For recommended manuals, cheatsheets, and curated video tutorials, see the [Resources Guide](resources.md).
