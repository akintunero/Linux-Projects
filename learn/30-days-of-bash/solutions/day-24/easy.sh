#!/usr/bin/env bash
# Day 24 easy: collect a name, a city and a number of retries, each with a default.
# The "typing" comes from a here-string; in a terminal you would type the answers.
set -euo pipefail

ask() {                                   # ask PROMPT DEFAULT  -> prints the answer
    local reply
    read -r -p "$1 [$2]: " reply || true
    echo "${reply:-$2}"
}

{
    read -r name_in
    read -r city_in
    read -r retries_in
} <<< $'\nBerlin\n'                       # name: empty, city: Berlin, retries: empty

name="$(ask 'Name' 'friend' <<< "$name_in")"
city="$(ask 'City' 'Paris' <<< "$city_in")"
retries="$(ask 'Retries' '3' <<< "$retries_in")"

echo "name=${name} city=${city} retries=${retries}"
