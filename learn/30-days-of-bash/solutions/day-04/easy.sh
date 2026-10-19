#!/usr/bin/env bash
# Day 04 easy: turn a score into a grade.
set -euo pipefail

score=73

if (( score >= 90 )); then
    grade="A"
elif (( score >= 80 )); then
    grade="B"
elif (( score >= 70 )); then
    grade="C"
else
    grade="F"
fi

echo "Score ${score} is grade ${grade}"
