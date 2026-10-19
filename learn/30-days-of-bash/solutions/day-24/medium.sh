#!/usr/bin/env bash
# Day 24 medium: confirm() that re-asks on bad input, accepts yes/no in any case,
# and returns failure (instead of looping forever) when input ends.
set -euo pipefail

confirm() {
    local reply
    while true; do
        read -r -p "$1 [y/n] " reply || { echo "(no answer: assuming no)" >&2; return 1; }
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     echo "please answer y or n" >&2 ;;
        esac
    done
}

run_case() {                              # run_case DESCRIPTION INPUT
    local result
    if confirm "Overwrite the file?" <<< "$2" 2>/dev/null; then result=yes; else result=no; fi
    printf '%-22s -> %s\n' "$1" "$result"
}

run_case "y"                     "y"
run_case "YES (capitals)"        "YES"
run_case "n"                     "n"
run_case "garbage then yes"      $'what?\nyes'
run_case "garbage then no"       $'what?\nno'
run_case "empty input (EOF)"     ""
