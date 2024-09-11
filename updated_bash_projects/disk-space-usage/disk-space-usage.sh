#!/bin/bash

# Set the start directory
START_DIR="/"

# Function to get disk usage
get_disk_usage() {
    local dir=$1
    local total_size=0
    for file in "$dir"/*; do
        if [ -f "$file" ]; then
            total_size=$((total_size + $(stat -c%s "$file")))
        elif [ -d "$file" ]; then
            total_size=$((total_size + $(get_disk_usage "$file")))
        fi
    done
    echo "$total_size"
}

# Function to generate report
generate_report() {
    local dir=$1
    local size=$(get_disk_usage "$dir")
    echo "Directory: $dir"
    echo "Size: $(echo "scale=2; $size / 1024 / 1024" | bc) MB"
    echo ""
}

# Generate report for each directory
for dir in "$START_DIR"/*; do
    if [ -d "$dir" ]; then
        generate_report "$dir"
    fi
done

# Generate summary
total_size=0
for dir in "$START_DIR"/*; do
    if [ -d "$dir" ]; then
        total_size=$((total_size + $(get_disk_usage "$dir")))
    fi
done
echo "Summary:"
echo "Total Size: $(echo "scale=2; $total_size / 1024 / 1024" | bc) MB"
