#!/usr/bin/env bash
# Fixed: keep the regex unquoted (in a variable), use -E for +, and escape the literal dots.
set -euo pipefail

ip="10.0.0.5"
re='^[0-9]+(\.[0-9]+){3}$'
if [[ $ip =~ $re ]]; then
    echo "valid ip"
else
    echo "invalid ip"
fi

printf 'order 42 shipped\n' | grep -E '[0-9]+' || echo "no number found"

printf 'v1x2y3\nv1.2.3\n' | grep -cE 'v[0-9]\.[0-9]\.[0-9]'
