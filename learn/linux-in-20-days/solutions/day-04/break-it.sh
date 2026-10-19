#!/usr/bin/env bash
# Day 04 - Break it (BUGGY on purpose). Run in an empty scratch directory.
# Goal: publish the "site" folder so the owner can edit, everyone can read, and
# directories can still be entered. Scripts in site/bin must stay runnable.
umask 000
mkdir -p site/bin site/css
printf '#!/bin/sh\necho deploy\n' > site/bin/deploy.sh
echo "body{}" > site/css/main.css

chmod -R 644 site

site/bin/deploy.sh
ls site/css
