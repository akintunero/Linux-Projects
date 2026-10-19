#!/usr/bin/env bash
# Day 14 - Break it (BUGGY on purpose). Run in a scratch directory containing a folder named "site".
# Usage: break-it.sh [SRC [DEST]]
# Goal: copy SRC's CONTENTS into DEST, make a tar.gz that restores anywhere, and say "backup ok"
# only if everything worked.
src=${1:-site}
dest=${2:-backup}

mkdir -p $dest
rsync -a $src $dest
tar -czf $dest/$src.tgz $PWD/$src
echo "backup ok"
