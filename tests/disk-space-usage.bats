#!/usr/bin/env bats
# Tests for projects/disk-space-usage/disk-space-usage.sh

load test_helper

setup() {
    make_workdir
    DISK="$REPO_ROOT/projects/disk-space-usage/disk-space-usage.sh"
    TREE="$WORKDIR/tree"
    mkdir -p "$TREE/big" "$TREE/small" "$TREE/dir with spaces"
    head -c 200000 /dev/zero >"$TREE/big/data.bin"
    echo "hello" >"$TREE/small/note.txt"
    echo "spaced" >"$TREE/dir with spaces/file.txt"
}

teardown() {
    cleanup_workdir
}

@test "script is executable" {
    [ -x "$DISK" ]
}

@test "-h and --help print usage and succeed" {
    run "$DISK" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Options:"* ]]
    run "$DISK" --help
    [ "$status" -eq 0 ]
}

@test "unknown option fails" {
    run "$DISK" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "missing directory fails" {
    run "$DISK" /nonexistent/directory
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist or is not accessible"* ]]
}

@test "analyzes the current directory by default" {
    cd "$TREE"
    run "$DISK"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Analyzing directory: ."* ]]
    [[ "$output" == *"Directory: ./big"* ]]
}

@test "lists the largest directory first" {
    run "$DISK" "$TREE"
    [ "$status" -eq 0 ]
    big_line=$(grep -n "Directory: $TREE/big" <<<"$output" | cut -d: -f1)
    small_line=$(grep -n "Directory: $TREE/small" <<<"$output" | cut -d: -f1)
    [ "$big_line" -lt "$small_line" ]
}

@test "reports file and directory counts" {
    run "$DISK" "$TREE"
    [[ "$output" == *"Files: 1"* ]]
    [[ "$output" == *"Directories: 0"* ]]
}

@test "handles directory names with spaces" {
    run "$DISK" "$TREE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Directory: $TREE/dir with spaces"* ]]
}

@test "bytes format prints a number of at least the file size" {
    run "$DISK" -f bytes -n 1 "$TREE"
    [ "$status" -eq 0 ]
    size=$(grep -m1 '^Size:' <<<"$output" | sed -E 's/^Size: ([0-9]+) bytes$/\1/')
    [[ "$size" =~ ^[0-9]+$ ]]
    [ "$size" -ge 200000 ]
}

@test "kb, mb and gb formats are accepted" {
    for fmt in kb mb gb human; do
        run "$DISK" -f "$fmt" "$TREE"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Size:"* ]]
    done
}

@test "invalid format is rejected" {
    run "$DISK" -f nonsense "$TREE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Invalid format"* ]]
}

@test "--top limits the number of entries" {
    run "$DISK" -n 1 "$TREE"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^Directory:' <<<"$output")" -eq 1 ]
}

@test "--depth reaches nested directories" {
    mkdir -p "$TREE/big/inner"
    run "$DISK" -d 1 "$TREE"
    [[ "$output" != *"inner"* ]]
    run "$DISK" -d 2 "$TREE"
    [[ "$output" == *"$TREE/big/inner"* ]]
}

@test "--depth must be a positive integer" {
    run "$DISK" -d zero "$TREE"
    [ "$status" -eq 2 ]
}

@test "--exclude hides a directory" {
    run "$DISK" -x "$TREE/big" "$TREE"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Directory: $TREE/big"* ]]
    [[ "$output" == *"Directory: $TREE/small"* ]]
}

@test "an empty directory reports no subdirectories" {
    mkdir "$WORKDIR/empty"
    run "$DISK" "$WORKDIR/empty"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No subdirectories found"* ]]
}

@test "--output writes a report only when asked" {
    run "$DISK" "$TREE"
    [ ! -e "$WORKDIR/report.txt" ]
    run "$DISK" -o "$WORKDIR/report.txt" "$TREE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Report saved to: $WORKDIR/report.txt"* ]]
    grep -q "Disk Space Usage Report" "$WORKDIR/report.txt"
    grep -q "Directory: $TREE" "$WORKDIR/report.txt"
    grep -q "Detailed Breakdown" "$WORKDIR/report.txt"
}

@test "--verbose shows a progress bar" {
    run "$DISK" -v "$TREE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Progress:"* ]]
}

@test "unreadable directories do not crash the scan" {
    if [ "$(id -u)" -eq 0 ]; then
        skip "root can read everything"
    fi
    mkdir "$TREE/locked"
    echo secret >"$TREE/locked/x"
    chmod 000 "$TREE/locked"
    run "$DISK" "$TREE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Summary Report"* ]]
}
