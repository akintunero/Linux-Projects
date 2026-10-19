#!/usr/bin/env bats
# Tests for projects/devops-scripts/docker-manager.sh
#
# The real docker binary is never needed: --dry-run prints commands, and a
# stub `docker` on PATH records calls for the non-dry-run cases.

load test_helper

setup() {
    make_workdir
    DM="$REPO_ROOT/projects/devops-scripts/docker-manager.sh"
}

teardown() {
    cleanup_workdir
}

@test "--help works without docker installed or running" {
    run env PATH="/usr/bin:/bin" "$DM" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commands:"* ]]
}

@test "no command prints usage and fails" {
    run "$DM"
    [ "$status" -eq 1 ]
    [[ "$output" == *"A command is required"* ]]
}

@test "unknown command and option are rejected" {
    run "$DM" --dry-run frobnicate
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
    run "$DM" --bogus list
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "dry-run prints docker commands without running docker" {
    run "$DM" --dry-run stop web db
    [ "$status" -eq 0 ]
    [[ "$output" == *"+ docker stop web"* ]]
    [[ "$output" == *"+ docker stop db"* ]]
}

@test "remove --force passes -f to docker rm" {
    run "$DM" --dry-run --force remove web
    [[ "$output" == *"+ docker rm -f web"* ]]
    run "$DM" --dry-run remove web
    [[ "$output" == *"+ docker rm web"* ]]
    [[ "$output" != *"rm -f"* ]]
}

@test "container names are validated" {
    run "$DM" --dry-run start 'web; rm -rf /'
    [ "$status" -eq 2 ]
    [[ "$output" == *"Invalid container name"* ]]
}

@test "commands that need names fail without any" {
    run "$DM" --dry-run start
    [ "$status" -eq 2 ]
}

@test "logs validates the line count" {
    run "$DM" --dry-run logs web abc
    [ "$status" -eq 2 ]
    run "$DM" --dry-run logs web 20
    [[ "$output" == *"+ docker logs --tail 20 web"* ]]
}

@test "list passes the filter through" {
    run "$DM" --dry-run list status=exited
    [[ "$output" == *"--filter status=exited"* ]]
}

@test "missing docker is reported clearly" {
    run env PATH="/usr/bin:/bin" bash -c "command -v docker >/dev/null && exit 99; '$DM' list"
    if [ "$status" -eq 99 ]; then
        skip "docker is installed in /usr/bin"
    fi
    [ "$status" -eq 127 ]
    [[ "$output" == *"missing required command"* ]]
}

@test "unreachable daemon is reported clearly" {
    make_stub docker 'if [ "$1" = info ]; then exit 1; fi'
    run "$DM" list
    [ "$status" -eq 3 ]
    [[ "$output" == *"Docker daemon"* ]]
}

@test "start reports success and failure per container" {
    make_stub docker 'case "$1" in info) exit 0;; start) [ "$2" = bad ] && exit 1; echo "$2";; esac'
    run "$DM" start good bad
    [ "$status" -eq 1 ]
    [[ "$output" == *"Started: good"* ]]
    [[ "$output" == *"Failed to start: bad"* ]]
}

@test "backup writes a tar into the requested file" {
    make_stub docker 'case "$1" in info) exit 0;; export) printf "TARDATA";; esac'
    run "$DM" backup web "$WORKDIR/out/web.tar"
    [ "$status" -eq 0 ]
    [ "$(cat "$WORKDIR/out/web.tar")" = "TARDATA" ]
}

@test "failed backup leaves no partial file" {
    make_stub docker 'case "$1" in info) exit 0;; export) exit 1;; esac'
    run "$DM" backup web "$WORKDIR/web.tar"
    [ "$status" -eq 1 ]
    [ ! -e "$WORKDIR/web.tar" ]
}
