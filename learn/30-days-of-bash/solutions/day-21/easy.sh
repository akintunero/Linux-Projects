#!/usr/bin/env bash
# Day 21 easy: validate semantic version strings such as v2.7.10 or 1.0.0-rc1.
set -euo pipefail

semver='^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.]+)?$'

for v in v2.7.10 1.0.0 1.0.0-rc1 1.0 v1.02.3 1.2.3.4 latest; do
    if [[ $v =~ $semver ]]; then
        echo "valid:   $v (major ${BASH_REMATCH[1]}, minor ${BASH_REMATCH[2]}, patch ${BASH_REMATCH[3]})"
    else
        echo "invalid: $v"
    fi
done
