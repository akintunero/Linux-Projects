#!/usr/bin/env bash
# Day 25 hard: a tiny test harness (assert_eq / assert_status) and tests for slugify.
# Prints a summary and exits non-zero when any test fails.
set -euo pipefail

# ---- the code under test (normally: source ./lib.sh) ------------------------------------
slugify() {
    local s="${1,,}"
    s="${s//[^a-z0-9]/-}"
    while [[ $s == *--* ]]; do s="${s//--/-}"; done
    s="${s#-}"
    s="${s%-}"
    printf '%s\n' "$s"
}

# ---- the harness ------------------------------------------------------------------------
tests_run=0
tests_failed=0

assert_eq() {                                  # assert_eq EXPECTED ACTUAL NAME
    tests_run=$(( tests_run + 1 ))
    if [[ $1 == "$2" ]]; then
        printf 'ok    %s\n' "$3"
    else
        tests_failed=$(( tests_failed + 1 ))
        printf 'FAIL  %s\n      expected: [%s]\n      actual:   [%s]\n' "$3" "$1" "$2"
    fi
}

assert_status() {                              # assert_status EXPECTED_STATUS NAME CMD...
    local expected="$1" name="$2" actual=0
    shift 2
    "$@" >/dev/null 2>&1 || actual=$?
    assert_eq "$expected" "$actual" "$name"
}

summary() {
    echo "${tests_run} run, $(( tests_run - tests_failed )) passed, ${tests_failed} failed"
    (( tests_failed == 0 ))
}

# ---- the tests --------------------------------------------------------------------------
assert_eq "hello-world"  "$(slugify 'Hello, World!')"        "punctuation becomes dashes"
assert_eq "mixed-case"   "$(slugify '  Mixed CASE  ')"       "trims and lowercases"
assert_eq "a-b"          "$(slugify 'a___b')"                "collapses repeated separators"
assert_eq "2025-report"  "$(slugify '2025 Report')"          "digits are kept"
assert_eq ""             "$(slugify '!!!')"                  "only punctuation gives an empty slug"
assert_status 0 "true succeeds"  true
assert_status 1 "false fails"    false

echo "--- negative control: the harness must notice a wrong expectation"
before=$tests_failed
assert_eq "wrong" "$(slugify 'Hello')" "deliberately wrong expectation" || true
if (( tests_failed == before + 1 )); then
    tests_failed=$before                      # forgive the planted failure...
    tests_run=$(( tests_run - 1 ))            # ...and do not count it as a real test
    echo "harness detected the planted failure"
fi

summary
