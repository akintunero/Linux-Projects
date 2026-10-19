#!/usr/bin/env bats
# Tests for projects/user-management/usermgmt.sh
#
# Everything here uses --dry-run (commands are printed, never executed) so the
# suite is safe to run on any machine and does not need root.

load test_helper

setup() {
    make_workdir
    UM="$REPO_ROOT/projects/user-management/usermgmt.sh"
}

teardown() {
    cleanup_workdir
}

@test "no arguments prints usage and fails" {
    run "$UM"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--help lists user and group commands" {
    run "$UM" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"create-user"* ]]
    [[ "$output" == *"add-to-group"* ]]
}

@test "unknown command fails" {
    run "$UM" --dry-run explode
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "non-root users are refused when not in dry-run" {
    if [ "$(id -u)" -eq 0 ]; then
        skip "running as root"
    fi
    run "$UM" create-group demo
    [ "$status" -eq 77 ]
    [[ "$output" == *"must be run as root"* ]]
}

@test "create-user prints the exact useradd command" {
    run "$UM" --dry-run create-user alice
    [ "$status" -eq 0 ]
    [[ "$output" == *"+ useradd -m -s /bin/bash -- alice"* ]]
}

@test "create-user honours --shell and --no-home" {
    run "$UM" --dry-run create-user svc --shell /usr/sbin/nologin --no-home
    [ "$status" -eq 0 ]
    [[ "$output" == *"+ useradd -M -s /usr/sbin/nologin -- svc"* ]]
}

@test "create-user --password-stdin never puts the password in the output" {
    run bash -c "printf 'hunter2\n' | '$UM' --dry-run create-user alice --password-stdin"
    [ "$status" -eq 0 ]
    [[ "$output" == *"chpasswd"* ]]
    [[ "$output" != *"hunter2"* ]]
}

@test "usernames are validated" {
    for bad in "Bad Name" "-rf" "a;b" "../etc" "" "UPPER" "$(printf 'a%.0s' {1..40})"; do
        run "$UM" --dry-run create-user "$bad"
        [ "$status" -eq 2 ]
    done
}

@test "root can never be targeted" {
    run "$UM" --dry-run delete-user root
    [ "$status" -eq 2 ]
    [[ "$output" == *"Refusing to operate on root"* ]]
}

@test "relative shell paths are rejected" {
    run "$UM" --dry-run create-user alice --shell bash
    [ "$status" -eq 2 ]
}

@test "delete-user removes the home directory unless told otherwise" {
    run "$UM" --dry-run delete-user alice
    [[ "$output" == *"+ userdel -r -- alice"* ]]
    run "$UM" --dry-run delete-user alice --keep-home
    [[ "$output" == *"+ userdel -- alice"* ]]
}

@test "lock-user and unlock-user use usermod -L / -U" {
    run "$UM" --dry-run lock-user alice
    [[ "$output" == *"+ usermod -L -- alice"* ]]
    run "$UM" --dry-run unlock-user alice
    [[ "$output" == *"+ usermod -U -- alice"* ]]
}

@test "set-expiry validates the date format" {
    run "$UM" --dry-run set-expiry alice 2030-01-31
    [ "$status" -eq 0 ]
    [[ "$output" == *"+ usermod -e 2030-01-31 -- alice"* ]]
    run "$UM" --dry-run set-expiry alice 31/01/2030
    [ "$status" -eq 2 ]
    run "$UM" --dry-run set-expiry alice 2030-13-45
    [ "$status" -eq 2 ]
}

@test "set-expiry never clears the expiry" {
    run "$UM" --dry-run set-expiry alice never
    [ "$status" -eq 0 ]
    [[ "$output" == *"usermod -e  -- alice"* ]]
}

@test "set-home requires an absolute path" {
    run "$UM" --dry-run set-home alice relative/path
    [ "$status" -eq 2 ]
    run "$UM" --dry-run set-home alice /srv/alice --move
    [[ "$output" == *"+ usermod -m -d /srv/alice -- alice"* ]]
}

@test "add-to-group appends instead of replacing groups" {
    run "$UM" --dry-run add-to-group alice docker
    [ "$status" -eq 0 ]
    [[ "$output" == *"+ usermod -a -G docker -- alice"* ]]
}

@test "group create/delete print the right commands" {
    run "$UM" --dry-run create-group devs
    [[ "$output" == *"+ groupadd -- devs"* ]]
    run "$UM" --dry-run delete-group devs
    [[ "$output" == *"+ groupdel -- devs"* ]]
}

@test "list-users runs without root and prints a header" {
    run "$UM" list-users
    [ "$status" -eq 0 ]
    [[ "$output" == *"Regular users"* ]]
}
