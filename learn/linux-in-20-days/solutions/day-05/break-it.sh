#!/usr/bin/env bash
# Day 05 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: change every standalone 80 to 8080 in app.conf and save the file.
printf 'port=80\nbackup_port=8080\nproxy=80 80\n' > app.conf
vim -es -c '%s/80/8080/' app.conf
cat app.conf
