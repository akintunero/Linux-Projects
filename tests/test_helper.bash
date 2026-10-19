# Shared setup for the Bats tests.
#
# Load it from a test file with:  load test_helper

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export REPO_ROOT
export NO_COLOR=1

# make_workdir - fresh scratch directory, removed again by cleanup_workdir
make_workdir() {
    WORKDIR="$(mktemp -d)"
    export WORKDIR
    cd "$WORKDIR" || return 1
}

cleanup_workdir() {
    # Tests that chmod 000 a directory must not block cleanup.
    chmod -R u+rwx "$WORKDIR" 2>/dev/null || true
    rm -rf "$WORKDIR"
}

# make_stub NAME [BODY] - create an executable NAME in $WORKDIR/bin and put
# that directory first on PATH. Use it to fake external commands.
make_stub() {
    local name="$1" body="${2:-exit 0}"
    mkdir -p "$WORKDIR/bin"
    printf '#!/usr/bin/env bash\n%s\n' "$body" >"$WORKDIR/bin/$name"
    chmod +x "$WORKDIR/bin/$name"
    case ":$PATH:" in
        *":$WORKDIR/bin:"*) ;;
        *) export PATH="$WORKDIR/bin:$PATH" ;;
    esac
}
