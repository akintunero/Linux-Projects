#!/usr/bin/env bash
# Fixed: the job sets its own PATH, uses absolute paths, and never relies on the working directory.
cat > job.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
base="$1"
export PATH="${base}/bin:/usr/local/bin:/usr/bin:/bin"
mytool
cat "${base}/data.txt"
EOF
mkdir bin
printf '#!/bin/sh\necho "mytool ok"\n' > bin/mytool
chmod +x bin/mytool
echo "report data" > data.txt
job="$PWD/job.sh"
base="$PWD"

echo "--- as you run it in your terminal"
bash "$job" "$base"

echo "--- as cron runs it (bare PATH, working directory /)"
(cd / && env -i PATH=/usr/bin:/bin bash "$job" "$base")
