#!/usr/bin/env bash
# Day 20 - Medium: capstone stages 1-2 (adds the timer-driven backup with verified restore).
# NEEDS-TOOL: systemd user manager, python3, curl (exit 77 if missing).
exec bash "$(dirname "${BASH_SOURCE[0]}")/capstone.sh" --stage 2
