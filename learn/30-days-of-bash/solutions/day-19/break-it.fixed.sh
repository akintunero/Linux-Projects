#!/usr/bin/env bash
# Fixed: use functions (they work in scripts and take arguments) instead of aliases.
ll() { ls -l "$@"; }
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

touch a.txt
ll a.txt | awk '{ print $NF }'
mkcd newdir
echo "now in: ${PWD##*/}"
