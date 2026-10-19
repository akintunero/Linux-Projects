#!/usr/bin/env bash
# Day 03 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: deploy release v2 so that links/current points at it, then print the version.
set -e
mkdir -p releases/v1 releases/v2 links
echo one > releases/v1/version.txt
echo two > releases/v2/version.txt

ln -s releases/v1 links/current        # first deploy
ln -s releases/v2 links/current        # second deploy
cat links/current/version.txt          # should print: two
