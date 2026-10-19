#!/usr/bin/env bash
# Day 13 - Break it (BUGGY on purpose). Read-only.
# Goal: print OVERLOADED when the 1-minute load average is higher than the number of CPUs,
# and print the percentage of memory really in use.
# Test overrides: NPROC=4 (CPU count), MEMINFO=file. The load average here comes from `uptime`.
cpus=${NPROC:-$(nproc)}
MEMINFO=${MEMINFO:-/proc/meminfo}

load=$(uptime | awk '{print $10}')
if [ $load -gt $cpus ]; then
  echo OVERLOADED
else
  echo load ok
fi

used=$(awk '/^MemTotal:/ {t=$2} /^MemFree:/ {f=$2} END {print (t-f)*100/t}' $MEMINFO)
echo "memory used: $used%"
