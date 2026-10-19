#!/usr/bin/env bash
# Day 04 medium: classify a file name by its extension (case-insensitive).
set -euo pipefail

file="Holiday.JPG"

case "${file,,}" in
    *.jpg|*.jpeg|*.png|*.gif) category="images" ;;
    *.txt|*.md|*.pdf)         category="documents" ;;
    *.zip|*.tar|*.tar.gz|*.tgz) category="archives" ;;
    *)                        category="other" ;;
esac

echo "${file} -> ${category}"
