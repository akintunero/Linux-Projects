#!/usr/bin/env bash
# Fixed: read -r, validate numbers before comparing, and apply defaults.
set -euo pipefail
exec < <(printf '%s\n' 'Ada\Lovelace' 'abc' '')

read -r -p "Name: " name
echo "name=[$name]"

read -r -p "Age: " age
case "$age" in
    ''|*[!0-9]*) echo "age must be a number (got '${age}')" ;;
    *)           if (( age > 17 )); then echo "adult"; fi ;;
esac

read -r -p "City (default Paris): " city
city="${city:-Paris}"
echo "city=[$city]"
