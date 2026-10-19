#!/usr/bin/env bash
# Day 07 easy: a system summary using the standard script skeleton.
set -euo pipefail

main() {
    echo "Kernel: $(uname -s)"
    echo "Arch:   $(uname -m)"
    echo "CPUs:   $(nproc)"
    echo "Shell:  ${SHELL##*/}"
}

main "$@"
