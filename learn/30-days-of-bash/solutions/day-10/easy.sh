#!/usr/bin/env bash
# Day 10 easy: split a path into parts with parameter expansion only.
set -euo pipefail

path="/home/ada/reports/q3-summary.final.pdf"

dir="${path%/*}"
file="${path##*/}"
stem="${file%.*}"
ext="${file##*.}"

echo "dir:  ${dir}"
echo "file: ${file}"
echo "stem: ${stem}"
echo "ext:  ${ext}"
