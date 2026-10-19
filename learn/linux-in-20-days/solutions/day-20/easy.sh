#!/usr/bin/env bash
# Day 20 - Easy: capstone stage 1 (service + health check). See capstone.sh.
# NEEDS-TOOL: systemd user manager, python3, curl (exit 77 if missing).
exec bash "$(dirname "${BASH_SOURCE[0]}")/capstone.sh" --stage 1
