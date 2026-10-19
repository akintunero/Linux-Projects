#!/usr/bin/env bash
# Day 06 easy: a greet function with a default argument.
set -euo pipefail

greet() {
    local name="${1:-friend}"
    echo "Hello, ${name}!"
}

greet "Ada"
greet
