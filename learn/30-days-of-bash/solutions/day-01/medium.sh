#!/usr/bin/env bash
# Day 01 medium: refuse to continue on a Bash older than 4.4.
major="${BASH_VERSINFO[0]}"
minor="${BASH_VERSINFO[1]}"

if (( major < 4 || (major == 4 && minor < 4) )); then
    echo "Need Bash 4.4 or newer, found ${major}.${minor}" >&2
    exit 1
fi
echo "Bash ${major}.${minor} is new enough."
