#!/usr/bin/env bash
# Day 02 hard: back up a tree and prove the copy is identical.
work="$(mktemp -d)"
cd "$work" || exit 1

mkdir -p project/{docs,src}
echo "first draft" > project/docs/readme.txt
echo 'echo hi' > project/src/app.sh

cp -a project project.bak              # -a keeps timestamps and permissions

if diff -r project project.bak >/dev/null; then
    echo "backup verified: identical"
else
    echo "backup differs" >&2
fi

echo "second draft" > project/docs/readme.txt
if diff -r project project.bak >/dev/null; then
    echo "still identical"
else
    echo "after editing: trees differ, as expected"
    diff -r project project.bak
fi

cd / && rm -rf -- "$work"
