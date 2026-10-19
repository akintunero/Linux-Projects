# Disk space usage analyzer

"Which folder is eating my disk?" This script lists subdirectories from largest to smallest, with file
and folder counts and a summary. It is a practical wrapper around `du` and `find`.

**You will practise:** option parsing, `du`/`find`/`sort`, arrays, `awk` for number formatting, handling
unreadable directories, and writing portable shell (GNU and BSD `du`).

## Usage

```bash
./disk-space-usage.sh                 # largest folders in the current directory
./disk-space-usage.sh -n 5 /var       # only the top five under /var
./disk-space-usage.sh -f mb -d 2 ~    # sizes in MB, two levels deep
./disk-space-usage.sh -x ~/Videos ~   # skip a folder
./disk-space-usage.sh -o report.txt . # also save a report
```

| Option | Meaning |
|--------|---------|
| `-f, --format` | `human` (default), `bytes`, `kb`, `mb`, `gb` |
| `-d, --depth N` | How many levels of subdirectories to list (default 1) |
| `-n, --top N` | Only the N largest |
| `-x, --exclude DIR` | Skip `DIR` (repeatable). `/proc /sys /dev /run` are skipped by default |
| `-o, --output FILE` | Also write the report to `FILE` (nothing is written unless you ask) |
| `-v, --verbose` | Progress bar |

Example output:

```text
Directory: /tmp/demo/big
Size: 195.31 KB
Files: 1
Directories: 0

Summary Report
==============
Total Size: 195.32 KB
Entries Listed: 2
```

Invalid options and values exit with a clear message (`2` for a bad value, `1` for a bad option or
missing directory). Unreadable directories are skipped, not fatal.

## How it works

1. `find -mindepth 1 -maxdepth N -type d -print0` collects directories, safe for names with spaces.
2. `du -sb` (or `du -sk` on macOS/BSD) measures each one; `|| true` keeps `set -e` from aborting on
   "Permission denied".
3. `sort -nr` orders the results; `awk` formats the numbers.

## Run the tests

```bash
bats ../../tests/disk-space-usage.bats
```

## Exercises

1. **Easy.** Add `--min SIZE` to hide entries smaller than a size such as `10M`.
2. **Medium.** Add `--json` output and validate it with `jq .`.
3. **Hard.** Add `--watch SECONDS` that re-runs and highlights directories that grew since last time.
