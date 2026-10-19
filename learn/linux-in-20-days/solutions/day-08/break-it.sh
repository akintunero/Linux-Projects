#!/usr/bin/env bash
# Day 08 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: list the biggest directories first (hidden ones included) and warn when
# the filesystem holding "." is more than 1% full (the threshold is low so you can see it fire).
mkdir -p tree/a tree/.cache
dd if=/dev/zero of=tree/a/big bs=1M count=3 status=none
dd if=/dev/zero of=tree/.cache/hidden bs=1M count=5 status=none

# shellcheck disable=SC2164  # intentionally left as-is: this file is the buggy exercise
cd tree
du -sh * | sort -n

usage=$(df . | awk 'NR==2 {print $5}')
if [ $usage -gt 1 ]; then
  echo "warning: filesystem is ${usage} full"
fi
