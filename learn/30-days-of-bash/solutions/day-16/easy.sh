#!/usr/bin/env bash
# Day 16 easy: greet every name given as an argument, or "world" if there are none.
# Run it as:  bash easy.sh Ada "Grace Hopper"
set -euo pipefail

if (( $# == 0 )); then
    set -- "world"                    # give ourselves a default argument list
fi

for name in "$@"; do
    echo "Hello, ${name}!"
done
echo "(${#} greeting(s))"
