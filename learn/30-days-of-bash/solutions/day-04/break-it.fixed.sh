#!/usr/bin/env bash
# Fixed: [[ ]] does not treat > as a redirection and tolerates empty variables;
# (( )) compares numbers.
set -euo pipefail

count=10
name=

if (( count > 5 )); then
    echo "count is big"
fi

if [[ -z $name ]]; then
    echo "no name given"
fi
ls
