#!/usr/bin/env bash
# Day 11 - Easy: print who you are: user, uid, primary group and supplementary groups.
# Read-only, no root needed.
set -euo pipefail

user=$(id -un)
uid=$(id -u)
group=$(id -gn)
groups=$(id -Gn)                 # all groups, space separated; the first is the primary group
echo "user=$user uid=$uid group=$group groups=$groups"

[[ $uid == "$(id -u)" && $groups == *"$group"* ]] || { echo "FAIL" >&2; exit 1; }
getent passwd "$user" | grep -q "^$user:x:$uid:" || { echo "FAIL: passwd entry differs" >&2; exit 1; }
echo PASS >&2
