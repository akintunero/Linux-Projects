#!/usr/bin/env bash
# Fixed: double quotes so the shell expands $new_host, a different delimiter so slashes
# need no escaping, and a temporary file instead of reading and writing the same file.
set -euo pipefail

printf 'host=db.example.com\nbase=/usr/local\n' > app.conf
new_host=cache.example.com

sed -i "s/^host=.*/host=${new_host}/" app.conf
cat app.conf

sed -i 's|^base=/usr/local|base=/opt|' app.conf

sed 's/=/ = /' app.conf > app.conf.new && mv app.conf.new app.conf
echo "final:"
cat app.conf
