#!/usr/bin/env bash
# Day 12 - Break it (BUGGY on purpose). Usage: break-it.sh HOST PORT
# Goal: report "web service is UP" only when the server answers HTTP successfully, within a few seconds.
host=$1
port=$2

if ping -c 1 $host > /dev/null; then
  curl http://$host:$port/
  echo "web service is UP"
else
  echo "web service is DOWN"
fi
