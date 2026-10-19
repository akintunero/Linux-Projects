#!/usr/bin/env bash
# Fixed: source the library relative to the script's own location, and keep the
# function's variable local so it cannot overwrite the caller's.
mkdir -p lib
cat > lib/util.sh <<'EOF'
greet() {
    local name="$1"
    echo "Hello, $name"
}
EOF

cat > run.sh <<'EOF'
#!/usr/bin/env bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib/util.sh"
name="Ada"
greet "Bob"
echo "name is now $name"
EOF

echo "--- from the script's own directory"
bash run.sh

echo "--- from somewhere else"
job="$PWD/run.sh"
(cd / && bash "$job")
