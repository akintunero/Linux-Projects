#!/usr/bin/env bash
# Day 10 - Medium: kill only YOUR sleeps by matching the full command line, leave others alone.
# Safe: starts its own sleeps with unusual durations and removes them.
set -euo pipefail

sleep 4242 & a=$!
sleep 4242 & b=$!
sleep 4343 & control=$!                  # must survive
trap 'kill "$control" 2>/dev/null || true' EXIT
sleep 0.2

# -f matches against the whole command line; -x would match only the name "sleep".
pkill -f 'sleep 4242' || true
wait "$a" 2>/dev/null || true
wait "$b" 2>/dev/null || true

if kill -0 "$a" 2>/dev/null || kill -0 "$b" 2>/dev/null; then echo "FAIL: targets alive" >&2; exit 1; fi
kill -0 "$control" 2>/dev/null           || { echo "FAIL: control process killed" >&2; exit 1; }
echo "targets gone, control still running"
echo PASS >&2
