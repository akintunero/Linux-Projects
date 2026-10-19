#!/usr/bin/env bash
# Day 01 easy: print a short "who am I" report.
user="${USER:-$(id -un)}"
echo "User:  $user"
echo "Shell: ${SHELL:-unknown}"
echo "Bash:  ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
