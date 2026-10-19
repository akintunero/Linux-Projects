#!/usr/bin/env bash
# Day 19 easy: write your aliases to a snippet file, load it, and use them.
# Temporary files only. In your real setup the snippet lives in ~/.bashrc or ~/.bashrc.d/.
shopt -s expand_aliases
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

cat > aliases.sh <<'EOF'
alias ll='ls -lA --color=never'
alias la='ls -A'
alias grep='grep --color=never -n'
alias gs='git status --short'
EOF

source ./aliases.sh                      # load them into this shell
touch notes.txt .secret

echo "--- defined aliases"
alias | sort

echo "--- ll shows hidden files too: $(ll | awk 'NR > 1 { print $NF }' | tr '\n' ' ')"
echo "--- la: $(la | tr '\n' ' ')"
echo "--- grep alias adds line numbers:"
printf 'one\ntwo\n' | grep tw

cd / && rm -rf -- "$work"
