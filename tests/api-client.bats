#!/usr/bin/env bats
# Tests for projects/devops-scripts/api-client.sh
#
# Network tests talk to a throw-away HTTP server on 127.0.0.1 (python3), so no
# internet access is required. They are skipped if python3 or jq is missing.

load test_helper

setup() {
    make_workdir
    API="$REPO_ROOT/projects/devops-scripts/api-client.sh"
    export API_CLIENT_CACHE_DIR="$WORKDIR/cache"
    export API_CLIENT_CONFIG="$WORKDIR/none.conf"
}

teardown() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
    cleanup_workdir
}

# start_server - serve $WORKDIR/www on a free port; sets BASE_URL
start_server() {
    command -v python3 >/dev/null || skip "python3 not installed"
    command -v jq >/dev/null || skip "jq not installed"
    mkdir -p "$WORKDIR/www"
    printf '{"name":"demo","stars":42}' >"$WORKDIR/www/repo.json"
    printf 'not json at all' >"$WORKDIR/www/plain.txt"
    port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
    # `exec` makes SERVER_PID the python process itself (so kill works), and
    # `3>&-` stops it holding Bats' output pipe open after the test ends.
    (cd "$WORKDIR/www" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 3>&-) &
    SERVER_PID=$!
    BASE_URL="http://127.0.0.1:$port"
    for _ in $(seq 1 50); do
        curl -s -o /dev/null "$BASE_URL/repo.json" && return 0
        sleep 0.1
    done
    skip "test server did not start"
}

@test "--help works without jq or network" {
    run "$API" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--cache"* ]]
}

@test "missing URL fails with usage" {
    run "$API"
    [ "$status" -eq 1 ]
    [[ "$output" == *"URL is required"* ]]
}

@test "non-http URLs are rejected" {
    for bad in "ftp://example.com" "example.com" "file:///etc/passwd" "javascript:alert(1)"; do
        run "$API" "$bad"
        [ "$status" -eq 2 ]
        [[ "$output" == *"Invalid URL"* ]]
    done
}

@test "unknown option, method and format are rejected" {
    run "$API" --bogus http://127.0.0.1:1/
    [ "$status" -eq 1 ]
    run "$API" -m TRACE http://127.0.0.1:1/
    [ "$status" -eq 2 ]
    run "$API" -f yaml http://127.0.0.1:1/
    [ "$status" -eq 2 ]
}

@test "there is no --key option that would leak secrets via ps" {
    run "$API" --key secret http://127.0.0.1:1/
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "invalid JSON body is rejected before any request" {
    command -v jq >/dev/null || skip "jq not installed"
    run "$API" -m POST -d '{oops' http://127.0.0.1:1/
    [ "$status" -eq 2 ]
    [[ "$output" == *"not valid JSON"* ]]
}

@test "GET returns pretty JSON" {
    start_server
    run "$API" "$BASE_URL/repo.json"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"name": "demo"'* ]]
}

@test "compact, table and raw formats" {
    start_server
    run "$API" -f compact "$BASE_URL/repo.json"
    [ "$output" = '{"name":"demo","stars":42}' ]
    run "$API" -f table "$BASE_URL/repo.json"
    [[ "$output" == *"name: demo"* ]]
    [[ "$output" == *"stars: 42"* ]]
    run "$API" -f raw "$BASE_URL/repo.json"
    [ "$output" = '{"name":"demo","stars":42}' ]
}

@test "non-JSON responses are printed as they are" {
    start_server
    run "$API" "$BASE_URL/plain.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "not json at all" ]
}

@test "a 404 fails with the HTTP status" {
    start_server
    run "$API" "$BASE_URL/missing.json"
    [ "$status" -eq 1 ]
    [[ "$output" == *"HTTP 404"* ]]
}

@test "--cache serves the second request from disk" {
    start_server
    run "$API" -c -f raw "$BASE_URL/repo.json"
    [ "$status" -eq 0 ]
    kill "$SERVER_PID"
    wait "$SERVER_PID" 2>/dev/null || true
    unset SERVER_PID
    run "$API" -c -f raw "$BASE_URL/repo.json"
    [ "$status" -eq 0 ]
    [ "$output" = '{"name":"demo","stars":42}' ]
}

@test "without --cache an unreachable server is an error" {
    run "$API" -t 1 http://127.0.0.1:1/
    [ "$status" -ne 0 ]
}
