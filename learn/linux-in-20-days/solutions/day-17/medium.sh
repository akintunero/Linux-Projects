#!/usr/bin/env bash
# Day 17 - Medium: a detached tmux session, driven without a terminal. Uses a private tmux socket
# (-L linux20-medium) so it can never touch your real sessions, and removes it at the end.
# NEEDS-TOOL: tmux (exits 77 if missing).
set -euo pipefail
command -v tmux >/dev/null || { echo "tmux missing" >&2; exit 77; }

t() { tmux -L linux20-medium "$@"; }
trap 't kill-server 2>/dev/null || true' EXIT
t kill-server 2>/dev/null || true

t new-session -d -s work 'echo hello-from-tmux; sleep 30'
t new-window -d -t work -n logs 'sleep 30'
sleep 0.5

t list-sessions -F '#{session_name}: #{session_windows} window(s)'
t list-windows -t work -F '#{window_index}:#{window_name}'
first=$(t capture-pane -p -t work:0 | head -n 1)
echo "pane shows: $first"

# Acceptance checks
[[ $(t list-sessions -F '#{session_name}') == work ]]               || { echo "FAIL: session" >&2; exit 1; }
[[ $(t list-windows -t work | wc -l) -eq 2 ]]                       || { echo "FAIL: two windows expected" >&2; exit 1; }
[[ $first == hello-from-tmux ]]                                     || { echo "FAIL: pane output" >&2; exit 1; }
t kill-server
! t has-session -t work 2>/dev/null                                 || { echo "FAIL: session survived kill-server" >&2; exit 1; }
echo PASS >&2
