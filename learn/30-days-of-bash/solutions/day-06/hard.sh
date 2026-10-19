#!/usr/bin/env bash
# Day 06 hard: a reusable retry function, tested with a flaky command.
# Safe: only touches a temporary directory.
set -euo pipefail

log() { echo "[retry] $*" >&2; }

# retry MAX_ATTEMPTS DELAY_SECONDS COMMAND [ARGS...]
retry() {
    local max="$1" delay="$2" attempt=1
    shift 2
    until "$@"; do
        if (( attempt >= max )); then
            log "giving up after ${attempt} attempts: $*"
            return 1
        fi
        log "attempt ${attempt} failed, retrying in ${delay}s"
        sleep "$delay"
        attempt=$(( attempt + 1 ))
    done
    log "succeeded on attempt ${attempt}"
}

work="$(mktemp -d)"
echo 0 > "$work/calls"

# Fails twice, then succeeds.
flaky() {
    local calls
    calls="$(< "$work/calls")"
    calls=$(( calls + 1 ))
    echo "$calls" > "$work/calls"
    (( calls >= 3 ))
}

retry 5 0 flaky && echo "flaky command worked"
echo 0 > "$work/calls"
retry 2 0 flaky || echo "retry reported failure with only 2 attempts"

rm -rf -- "$work"
