#!/usr/bin/env bash
# Day 03 easy: greeting card with variables and arithmetic.
set -euo pipefail

name="Ada"
city="London"
age=36
to_go=$(( 100 - age ))

echo "${name} from ${city} is ${age}; ${to_go} years to go."
