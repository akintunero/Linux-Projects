#!/usr/bin/env bash
# Day 19 - Break it: build a small web "application" that is broken in THREE ways, then try to start it.
# Everything happens inside DIR and on 127.0.0.1; nothing outside DIR is touched.
# Usage:  bash break-it.sh [DIR]            (default ./lab)  create the broken app and try to start it
#         bash break-it.sh --cleanup DIR    stop the blocker process and delete DIR
# Your job: make `./start.sh` serve the page, using only diagnosis (do not read this file for the answers).
# NEEDS-TOOL: python3.
set -euo pipefail

if [[ ${1:-} == --cleanup ]]; then
  dir=${2:?usage: break-it.sh --cleanup DIR}
  if [[ -f $dir/blocker.pid ]]; then kill "$(cat "$dir/blocker.pid")" 2>/dev/null || true; fi
  rm -rf -- "$dir"
  echo "cleaned up $dir"
  exit 0
fi

command -v python3 >/dev/null || { echo "python3 missing" >&2; exit 77; }
dir=${1:-lab}
mkdir -p -- "$dir/site" "$dir/blocker-root"
echo '<h1>app is up</h1>' > "$dir/site/index.html"

port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')

cat > "$dir/start.sh" <<'EOF'
#!/usr/bin/env bash
# Starts the demo web app using settings from app.conf.
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./app.conf
: "${PORT:?PORT is not set in app.conf}"
: "${DATA_DIR:?DATA_DIR is not set in app.conf}"
echo "starting on 127.0.0.1:$PORT serving $DATA_DIR"
exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$DATA_DIR"
EOF
chmod 644 "$dir/start.sh"                                   # fault 1: not executable
printf 'PROT=%s\nDATA_DIR=./site\n' "$port" > "$dir/app.conf" # fault 2: key is misspelled

# fault 3: some other process already listens on that port
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$dir/blocker-root" >/dev/null 2>&1 &
echo $! > "$dir/blocker.pid"
sleep 1

echo "Lab created in $dir. Try:   cd $dir && ./start.sh"
echo "When you are done:          bash $0 --cleanup $dir"
