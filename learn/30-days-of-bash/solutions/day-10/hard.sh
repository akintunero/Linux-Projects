#!/usr/bin/env bash
# Day 10 hard: take a URL apart with parameter expansion only.
set -euo pipefail

url="https://deploy@example.com:8443/app/status?verbose=1&fmt=json"

scheme="${url%%://*}"
rest="${url#*://}"                  # deploy@example.com:8443/app/status?verbose=1&fmt=json

query=""
if [[ $rest == *\?* ]]; then
    query="${rest#*\?}"
    rest="${rest%%\?*}"
fi

hostport="${rest%%/*}"
path="/${rest#*/}"
[[ $rest == */* ]] || path="/"

user=""
if [[ $hostport == *@* ]]; then
    user="${hostport%@*}"
    hostport="${hostport#*@}"
fi

host="${hostport%%:*}"
port=""
if [[ $hostport == *:* ]]; then
    port="${hostport##*:}"
else
    case "$scheme" in https) port=443 ;; http) port=80 ;; esac
fi

printf '%-7s %s\n' scheme "$scheme" user "$user" host "$host" port "$port" path "$path" query "$query"
