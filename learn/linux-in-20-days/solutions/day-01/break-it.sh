#!/usr/bin/env bash
# Day 01 - Break it (BUGGY on purpose). Find and fix the three bugs.
# It should print the package manager for the distribution in $OS_RELEASE.
OS_RELEASE=${OS_RELEASE:-/etc/os-release}
source /etc/os-releas

if [ $ID_LIKE = "debian" ]; then
  echo "apt"
else
  echo "dnf"
fi
