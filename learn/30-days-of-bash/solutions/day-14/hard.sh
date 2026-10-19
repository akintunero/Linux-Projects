#!/usr/bin/env bash
# Day 14 hard: send the xtrace to its own file so normal output stays clean.
# Temporary files only.
set -euo pipefail

work="$(mktemp -d)"
trace="${work}/trace.log"

exec 5> "$trace"                         # open file descriptor 5 for writing
BASH_XTRACEFD=5                          # xtrace now goes to fd 5, not stderr
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '

greet() {
    local who="$1"
    echo "hello, ${who}"
}

set -x
greet "Ada"
result="$(greet "Grace")"
set +x

echo "stdout stayed clean: ${result}"
echo "--- first lines of the trace file"
head -n 6 "$trace"
echo "--- trace lines mentioning greet: $(grep -c 'greet' "$trace")"

exec 5>&-                                # close fd 5
rm -rf -- "$work"
