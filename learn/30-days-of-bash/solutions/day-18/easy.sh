#!/usr/bin/env bash
# Day 18 easy: which variables does a child process inherit?
set -euo pipefail

# shellcheck disable=SC2034  # deliberately not exported: the demo shows the child cannot see it
not_exported="visible only here"
export exported="visible to children"

bash -c 'echo "child: not_exported=[${not_exported:-}]"'
bash -c 'echo "child: exported=[${exported:-}]"'

echo "--- one-shot assignment"
LOG_LEVEL=debug bash -c 'echo "child: LOG_LEVEL=${LOG_LEVEL}"'
echo "parent: LOG_LEVEL=[${LOG_LEVEL:-}]"

echo "--- is it in the environment?"
if printenv exported >/dev/null; then echo "exported: yes"; else echo "exported: no"; fi
if printenv not_exported >/dev/null; then echo "not_exported: yes"; else echo "not_exported: no"; fi
