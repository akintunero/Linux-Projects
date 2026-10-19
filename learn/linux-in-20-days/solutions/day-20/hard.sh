#!/usr/bin/env bash
# Day 20 - Hard: the full capstone including the failure drill (stage 3). See capstone.sh.
# NEEDS-TOOL: systemd user manager, python3, curl (exit 77 if missing).
exec bash "$(dirname "${BASH_SOURCE[0]}")/capstone.sh" --stage 3
