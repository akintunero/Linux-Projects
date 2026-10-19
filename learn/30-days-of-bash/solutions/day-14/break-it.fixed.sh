#!/usr/bin/env bash
# Fixed: "then" was missing, and totl was a typo for a variable that must exist.
set -euo pipefail

name="report"
total=3
if [[ -n $name ]]; then
    echo "have a name"
fi
echo "Total: $total"
