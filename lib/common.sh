#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2034
#
# lib/common.sh - helpers shared by the scripts in projects/.
#
# Source it from a script with:
#   source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
#
# Conventions
#   - Status messages for the user go to stdout via `msg`/`ok`.
#   - Warnings and errors go to stderr via `warn`/`err`/`die`.
#   - Colour is only used on a terminal and is disabled by NO_COLOR=1.

# Guard against being sourced twice.
if [[ -n "${_LP_COMMON_LOADED:-}" ]]; then
    return 0
fi
_LP_COMMON_LOADED=1

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\033[0;31m'
    C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[1;33m'
    C_BLUE=$'\033[0;34m'
    C_CYAN=$'\033[0;36m'
    C_RESET=$'\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN='' C_RESET=''
fi

# msg TEXT...  - plain informational line (stdout)
msg() { printf '%s\n' "$*"; }

# info/ok/warn/err TEXT... - coloured status lines
info() { printf '%s%s%s\n' "$C_BLUE" "$*" "$C_RESET"; }
ok() { printf '%s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '%sWarning: %s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2; }
err() { printf '%sError: %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; }

# die MESSAGE [EXIT_CODE] - print an error and exit (default exit code 1)
die() {
    err "$1"
    exit "${2:-1}"
}

# log LEVEL MESSAGE... - append a timestamped line to $LOG_FILE (if set)
log() {
    [[ -n "${LOG_FILE:-}" ]] || return 0
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >>"$LOG_FILE"
}

# require_cmd CMD... - exit with an install hint when a dependency is missing
require_cmd() {
    local missing=() cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if ((${#missing[@]} > 0)); then
        err "missing required command(s): ${missing[*]}"
        msg "Install on Debian/Ubuntu: sudo apt-get install ${missing[*]}" >&2
        msg "Install on RHEL/Fedora:   sudo dnf install ${missing[*]}" >&2
        msg "Install on macOS:         brew install ${missing[*]}" >&2
        exit 127
    fi
}

# require_root - exit unless running as root
require_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        die "this command must be run as root (try: sudo $0 ...)" 77
    fi
}

# is_positive_int VALUE
is_positive_int() { [[ "${1:-}" =~ ^[0-9]+$ ]] && ((10#$1 > 0)); }

# valid_username NAME - POSIX-portable login name, 1-32 chars
valid_username() { [[ "${1:-}" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; }

# file_mtime FILE - modification time in epoch seconds (GNU and BSD stat)
file_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

# hash_string STRING - stable hex digest (sha256sum, shasum, or md5)
hash_string() {
    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s' "$1" | sha256sum | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1
    else
        printf '%s' "$1" | md5 -q
    fi
}
