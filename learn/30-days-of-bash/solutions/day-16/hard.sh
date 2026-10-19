#!/usr/bin/env bash
# Day 16 hard: long options (--lines=5, --lines 5, --verbose, --help, --) with a while/case/shift loop.
# The parser is exercised with fixed argument lists, so the script is self-contained.
set -euo pipefail

parse() {
    lines=10; verbose=0; files=()
    while (( $# > 0 )); do
        case "$1" in
            -n|--lines)
                [[ $# -ge 2 ]] || { echo "error: $1 needs a value" >&2; return 2; }
                lines="$2"; shift 2 ;;
            --lines=*)   lines="${1#*=}"; shift ;;
            -v|--verbose) verbose=1; shift ;;
            -h|--help)   echo "usage: tool [-n|--lines N] [-v|--verbose] FILE..."; return 10 ;;
            --)          shift; files+=("$@"); break ;;       # everything after -- is a file
            -*)          echo "error: unknown option $1" >&2; return 2 ;;
            *)           files+=("$1"); shift ;;
        esac
    done
    case "$lines" in ''|*[!0-9]*) echo "error: lines must be a number, got '$lines'" >&2; return 2 ;; esac
    (( ${#files[@]} > 0 )) || { echo "error: no files" >&2; return 2; }
}

try() {
    local status=0
    echo "\$ tool $*"
    parse "$@" || status=$?
    if (( status == 0 )); then
        echo "  lines=${lines} verbose=${verbose} files=(${files[*]})"
    else
        echo "  parse returned ${status}"
    fi
}

try --lines=5 -v a.txt "b c.txt"
try --lines 7 a.txt
try -n 2 -- -weird-name.txt
try --lines
try --bogus a.txt
try --help
