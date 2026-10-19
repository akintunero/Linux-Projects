#!/usr/bin/env bash
# Day 16 - Break it (BUGGY on purpose). A job that tries to avoid running twice with a lock file.
# Usage: LOCKDIR=/tmp bash break-it.sh      (run it twice at the same time, then kill one and run again)
# Goals: (a) two simultaneous runs must not both work, (b) a run that is killed must not block future
# runs, (c) it must behave the same no matter which directory it is started from (cron starts jobs in $HOME).
lock=job.lock

if [ -f $lock ]; then
  echo "already running, skipping"
  exit 0
fi
touch $lock

echo "start"
sleep 5
echo "done"

rm $lock
