#!/usr/bin/env bash
# Day 20 hard: a tiny cron-expression matcher: does "m h dom mon dow" fire at "YYYY-MM-DD HH:MM"?
# Supports *, lists (1,15), ranges (9-17) and steps (*/15, 0-30/10). Pure Bash + date.
set -euo pipefail

# field_matches FIELD VALUE MIN MAX
field_matches() {
    local field="$1" value=$(( 10#$2 )) min="$3" max="$4"
    local part range step lo hi
    local -a parts
    IFS=, read -ra parts <<< "$field"
    for part in "${parts[@]}"; do
        range="${part%%/*}"
        step=1
        [[ $part == */* ]] && step="${part#*/}"
        if [[ $range == '*' ]]; then
            lo=$min; hi=$max
        elif [[ $range == *-* ]]; then
            lo="${range%-*}"; hi="${range#*-}"
        else
            lo="$range"; hi="$range"
        fi
        if (( value >= lo && value <= hi && (value - lo) % step == 0 )); then
            return 0
        fi
    done
    return 1
}

# cron_match "M H DOM MON DOW" "YYYY-MM-DD HH:MM"
cron_match() {
    local f_min f_hour f_dom f_mon f_dow day clock mo d hh mm dow
    read -r f_min f_hour f_dom f_mon f_dow <<< "$1"
    read -r day clock <<< "$2"
    IFS=- read -r _ mo d <<< "$day"
    IFS=: read -r hh mm <<< "$clock"
    dow="$(date -d "$day" +%w)"                        # 0 = Sunday

    field_matches "$f_min"  "$mm" 0 59 || return 1
    field_matches "$f_hour" "$hh" 0 23 || return 1
    field_matches "$f_mon"  "$mo" 1 12 || return 1
    # Classic cron rule: if BOTH day fields are restricted, either may match.
    local dom_ok=1 dow_ok=1
    field_matches "$f_dom" "$d" 1 31 && dom_ok=0 || true
    field_matches "${f_dow/7/0}" "$dow" 0 6 && dow_ok=0 || true
    if [[ $f_dom != '*' && $f_dow != '*' ]]; then
        (( dom_ok == 0 || dow_ok == 0 ))
    else
        (( dom_ok == 0 && dow_ok == 0 ))
    fi
}

passed=0 failed=0
check() {                                              # check EXPR WHEN EXPECTED(yes|no)
    local result=no
    cron_match "$1" "$2" && result=yes
    if [[ $result == "$3" ]]; then
        passed=$(( passed + 1 )); printf 'pass  %-18s %s -> %s\n' "$1" "$2" "$result"
    else
        failed=$(( failed + 1 )); printf 'FAIL  %-18s %s -> %s (wanted %s)\n' "$1" "$2" "$result" "$3"
    fi
}

check "*/15 9-17 * * 1-5" "2025-10-10 09:30" yes     # a Friday
check "*/15 9-17 * * 1-5" "2025-10-10 09:31" no      # not on the quarter hour
check "*/15 9-17 * * 1-5" "2025-10-11 09:30" no      # a Saturday
check "0 2 * * *"         "2025-10-10 02:00" yes
check "0 2 * * *"         "2025-10-10 02:01" no
check "30 4 1,15 * *"     "2025-10-15 04:30" yes
check "30 4 1,15 * *"     "2025-10-16 04:30" no
check "0 0 * * 0"         "2025-10-12 00:00" yes     # a Sunday
check "0 0 * * 7"         "2025-10-12 00:00" yes     # 7 also means Sunday
check "0-30/10 * * * *"   "2025-10-10 12:20" yes
check "0-30/10 * * * *"   "2025-10-10 12:40" no

echo "${passed} passed, ${failed} failed"
(( failed == 0 ))
