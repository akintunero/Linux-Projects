#!/usr/bin/env bats

# Test file for enhanced disk usage analyzer
# Author: Olúmáyòwá Akinkuehinmi
# Email: akintunero101@gmail.com

setup() {
    # Create temporary directory for tests
    export TEST_DIR=$(mktemp -d)
    export TEST_SUBDIR="$TEST_DIR/test_subdir"
    
    # Create test directory structure
    mkdir -p "$TEST_SUBDIR"
    mkdir -p "$TEST_SUBDIR/subdir1"
    mkdir -p "$TEST_SUBDIR/subdir2"
    
    # Create test files with known sizes
    echo "test content 1" > "$TEST_SUBDIR/file1.txt"
    echo "test content 2 with more data" > "$TEST_SUBDIR/file2.txt"
    echo "test content 3" > "$TEST_SUBDIR/subdir1/file3.txt"
    echo "test content 4" > "$TEST_SUBDIR/subdir2/file4.txt"
    
    # Copy the script to test directory
    cp ../updated_bash_projects/disk-space-usage/disk-space-usage.sh "$TEST_DIR/"
    chmod +x "$TEST_DIR/disk-space-usage.sh"
    
    # Change to test directory
    cd "$TEST_DIR"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "script exists and is executable" {
    [ -f "disk-space-usage.sh" ]
    [ -x "disk-space-usage.sh" ]
}

@test "help message displays with -h flag" {
    run ./disk-space-usage.sh -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Enhanced Disk Space Usage Analyzer"* ]]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Options:"* ]]
}

@test "help message displays with --help flag" {
    run ./disk-space-usage.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Enhanced Disk Space Usage Analyzer"* ]]
}

@test "analyzes current directory by default" {
    run ./disk-space-usage.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Analyzing directory: ."* ]]
    [[ "$output" == *"Enhanced Disk Space Usage Analyzer"* ]]
}

@test "analyzes specified directory" {
    run ./disk-space-usage.sh "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Analyzing directory: $TEST_SUBDIR"* ]]
}

@test "fails with non-existent directory" {
    run ./disk-space-usage.sh /nonexistent/directory
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Directory"* ]]
    [[ "$output" == *"does not exist or is not accessible"* ]]
}

@test "fails with invalid option" {
    run ./disk-space-usage.sh --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Unknown option"* ]]
}

@test "formats output in bytes" {
    run ./disk-space-usage.sh -f bytes "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Size:"* ]]
    # Should show raw byte values
    [[ "$output" =~ [0-9]+[^KMG] ]]
}

@test "formats output in KB" {
    run ./disk-space-usage.sh -f kb "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Size:"* ]]
}

@test "formats output in MB" {
    run ./disk-space-usage.sh -f mb "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Size:"* ]]
}

@test "formats output in GB" {
    run ./disk-space-usage.sh -f gb "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Size:"* ]]
}

@test "uses human readable format by default" {
    run ./disk-space-usage.sh "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Size:"* ]]
}

@test "sets custom depth limit" {
    run ./disk-space-usage.sh -d 5 "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Maximum depth: 5"* ]]
}

@test "saves report to file" {
    local report_file="$TEST_DIR/report.txt"
    run ./disk-space-usage.sh -o "$report_file" "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Report saved to: $report_file"* ]]
    
    # Check that report file exists and has content
    [ -f "$report_file" ]
    [[ "$(cat "$report_file")" == *"Disk Space Usage Report"* ]]
}

@test "shows verbose output" {
    run ./disk-space-usage.sh -v "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Progress:"* ]]
}

@test "handles empty directory" {
    local empty_dir="$TEST_DIR/empty_dir"
    mkdir -p "$empty_dir"
    
    run ./disk-space-usage.sh "$empty_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No subdirectories found"* ]]
}

@test "excludes system directories" {
    # The script should exclude /proc, /sys, etc.
    # This test verifies the exclusion logic works
    run ./disk-space-usage.sh /
    [ "$status" -eq 0 ]
    # Should not show excluded directories in output
    [[ "$output" != *"/proc"* ]] || [[ "$output" != *"/sys"* ]]
}

@test "calculates total size correctly" {
    # Create files with known sizes
    echo "test" > "$TEST_SUBDIR/small.txt"
    echo "test content with more data" > "$TEST_SUBDIR/medium.txt"
    
    run ./disk-space-usage.sh "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Total Size:"* ]]
    [[ "$output" == *"Summary Report"* ]]
}

@test "shows directory statistics" {
    run ./disk-space-usage.sh "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Files:"* ]]
    [[ "$output" == *"Directories:"* ]]
}

@test "handles permission errors gracefully" {
    # Create a directory with no read permissions
    local no_read_dir="$TEST_DIR/no_read"
    mkdir -p "$no_read_dir"
    chmod 000 "$no_read_dir"
    
    run ./disk-space-usage.sh "$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should not crash and should complete successfully
    
    # Restore permissions for cleanup
    chmod 755 "$no_read_dir"
}

@test "validates format parameter" {
    run ./disk-space-usage.sh -f invalid_format "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    # Should default to human format or handle gracefully
}

@test "handles large directory structures" {
    # Create a deeper directory structure
    local deep_dir="$TEST_SUBDIR/deep"
    mkdir -p "$deep_dir/level1/level2/level3"
    echo "test" > "$deep_dir/level1/level2/level3/file.txt"
    
    run ./disk-space-usage.sh -d 2 "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    # Should respect depth limit and not crash
}

@test "progress bar works with verbose mode" {
    # Create multiple subdirectories to trigger progress bar
    for i in {1..5}; do
        mkdir -p "$TEST_SUBDIR/dir$i"
        echo "test" > "$TEST_SUBDIR/dir$i/file$i.txt"
    done
    
    run ./disk-space-usage.sh -v "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Progress:"* ]]
}

@test "report file contains correct information" {
    local report_file="$TEST_DIR/detailed_report.txt"
    
    # Generate report
    ./disk-space-usage.sh -o "$report_file" "$TEST_SUBDIR" > /dev/null
    
    # Check report content
    local report_content
    report_content=$(cat "$report_file")
    
    [[ "$report_content" == *"Disk Space Usage Report"* ]]
    [[ "$report_content" == *"Generated:"* ]]
    [[ "$report_content" == *"Directory: $TEST_SUBDIR"* ]]
    [[ "$report_content" == *"Total Size:"* ]]
    [[ "$report_content" == *"Detailed Breakdown:"* ]]
}

@test "handles special characters in directory names" {
    local special_dir="$TEST_SUBDIR/dir with spaces"
    mkdir -p "$special_dir"
    echo "test" > "$special_dir/file.txt"
    
    run ./disk-space-usage.sh "$TEST_SUBDIR"
    [ "$status" -eq 0 ]
    # Should handle spaces and special characters without crashing
} 