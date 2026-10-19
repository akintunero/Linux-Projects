#!/usr/bin/env bash
# Day 27 hard: run_job runs any command with a time limit, logs the result and maps exit codes.
# Safe: it only runs sleep, true and false.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
logfile="${work}/jobs.log"

# run_job NAME TIMEOUT_SECONDS COMMAND [ARGS...]
run_job() {
    local name="$1" limit="$2" status=0 verdict
    shift 2
    if command -v "$1" >/dev/null 2>&1; then
        timeout "$limit" "$@" || status=$?
    else
        status=127                              # check first: clearer than timeout's own message
    fi
    case "$status" in
        0)   verdict="ok" ;;
        124) verdict="TIMED OUT after ${limit}s" ;;
        127) verdict="command not found" ;;
        *)   verdict="failed with status ${status}" ;;
    esac
    printf '%s: %s\n' "$name" "$verdict" | tee -a "$logfile"
    return "$status"
}

total=0
failed=0
run_all() {
    while IFS='|' read -r name limit cmd; do
        total=$(( total + 1 ))
        # shellcheck disable=SC2086   # deliberate word splitting of a simple, trusted command line
        run_job "$name" "$limit" $cmd || failed=$(( failed + 1 ))
    done
}

run_all <<'EOF'
quick job|2|true
failing job|2|false
hanging job|1|sleep 5
missing tool|2|definitely-not-installed
EOF

echo "--- summary: ${failed} of ${total} jobs did not succeed"
echo "log has $(wc -l < "$logfile") lines"
