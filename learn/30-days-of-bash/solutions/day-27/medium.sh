#!/usr/bin/env bash
# Day 27 medium: run several health checks in parallel and report in a stable order.
# The "checks" are simulated with sleep so the script is self-contained and harmless.
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

# check NAME DELAY EXIT_CODE : pretend to probe a service
check() {
    local name="$1" delay="$2" code="$3"
    sleep "$delay"
    if (( code == 0 )); then
        echo "ok" > "${work}/${name}.result"
    else
        echo "failed (code ${code})" > "${work}/${name}.result"
    fi
    return "$code"
}

declare -A pids
declare -a names=(database cache queue web)
check database 0.4 0 & pids[database]=$!
check cache    0.1 1 & pids[cache]=$!
check queue    0.3 0 & pids[queue]=$!
check web      0.2 2 & pids[web]=$!

failures=0
for name in "${names[@]}"; do                 # fixed order, whatever finishes first
    status=0
    wait "${pids[$name]}" || status=$?
    printf '%-9s %s\n' "$name" "$(< "${work}/${name}.result")"
    (( status == 0 )) || failures=$(( failures + 1 ))
done

echo "${failures} of ${#names[@]} checks failed"
