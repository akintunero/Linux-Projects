#!/bin/bash
set -euo pipefail

# Enhanced Disk Space Usage Analyzer
# Author: Olúmáyòwá Akinkuehinmi
# Email: akintunero101@gmail.com
# Version: 2.0.0

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MAX_DEPTH=10
readonly EXCLUDE_PATTERNS=("/proc" "/sys" "/dev" "/run" "/tmp")
OUTPUT_FORMAT="human"  # human, bytes, kb, mb, gb
readonly REPORT_FILE="${SCRIPT_DIR}/disk_usage_report.txt"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to convert bytes to human readable format
format_size() {
    local bytes="$1"
    local format="${2:-human}"
    
    case $format in
        "bytes")
            echo "$bytes"
            ;;
        "kb")
            echo "scale=2; $bytes / 1024" | bc -l
            ;;
        "mb")
            echo "scale=2; $bytes / 1024 / 1024" | bc -l
            ;;
        "gb")
            echo "scale=2; $bytes / 1024 / 1024 / 1024" | bc -l
            ;;
        "human")
            if [[ $bytes -gt 1073741824 ]]; then
                echo "scale=2; $bytes / 1073741824" | bc -l | sed 's/^/0/' | sed 's/^0*//' | sed 's/^$/0/' && echo " GB"
            elif [[ $bytes -gt 1048576 ]]; then
                echo "scale=2; $bytes / 1048576" | bc -l | sed 's/^/0/' | sed 's/^0*//' | sed 's/^$/0/' && echo " MB"
            elif [[ $bytes -gt 1024 ]]; then
                echo "scale=2; $bytes / 1024" | bc -l | sed 's/^/0/' | sed 's/^0*//' | sed 's/^$/0/' && echo " KB"
            else
                echo "$bytes bytes"
            fi
            ;;
        *)
            echo "$bytes"
            ;;
    esac
}

# Function to check if directory should be excluded
is_excluded() {
    local dir="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$dir" == "$pattern" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to get disk usage with depth limit and exclusions
get_disk_usage() {
    local dir="$1"
    local depth="${2:-0}"
    local total_size=0
    
    # Check depth limit
    if [[ $depth -gt $MAX_DEPTH ]]; then
        return 0
    fi
    
    # Check if directory should be excluded
    if is_excluded "$dir"; then
        return 0
    fi
    
    # Check if directory exists and is readable
    if [[ ! -d "$dir" ]] || [[ ! -r "$dir" ]]; then
        return 0
    fi
    
    # Use find command for better performance and error handling
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
        fi
    done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)
    
    # Recursively process subdirectories
    while IFS= read -r -d '' subdir; do
        if [[ -d "$subdir" ]] && [[ "$subdir" != "$dir" ]]; then
            sub_size=$(get_disk_usage "$subdir" $((depth + 1)))
            total_size=$((total_size + sub_size))
        fi
    done < <(find "$dir" -maxdepth 1 -type d -print0 2>/dev/null)
    
    echo "$total_size"
}

# Function to generate detailed report
generate_report() {
    local dir="$1"
    local size
    size=$(get_disk_usage "$dir")
    
    if [[ $size -gt 0 ]]; then
        local formatted_size
        formatted_size=$(format_size "$size" "$OUTPUT_FORMAT")
        print_message "$BLUE" "Directory: $dir"
        print_message "$GREEN" "Size: $formatted_size"
        print_message "$YELLOW" "Files: $(find "$dir" -type f 2>/dev/null | wc -l)"
        print_message "$PURPLE" "Directories: $(find "$dir" -type d 2>/dev/null | wc -l)"
        echo ""
    fi
}

# Function to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local percentage=$((current * 100 / total))
    printf "\rProgress: [%-50s] %d%%" "$(printf '#%.0s' $(seq 1 $((percentage / 2))))" "$percentage"
}

# Function to display help
show_help() {
    print_message "$CYAN" "Enhanced Disk Space Usage Analyzer"
    print_message "$CYAN" "=================================="
    echo ""
    print_message "$YELLOW" "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo ""
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "  -h, --help          Show this help message"
    print_message "$YELLOW" "  -f, --format FORMAT  Output format (human, bytes, kb, mb, gb)"
    print_message "$YELLOW" "  -d, --depth N        Maximum directory depth (default: 10)"
    print_message "$YELLOW" "  -o, --output FILE    Save report to file"
    print_message "$YELLOW" "  -v, --verbose        Verbose output"
    echo ""
    print_message "$YELLOW" "Examples:"
    print_message "$YELLOW" "  $0                    # Analyze current directory"
    print_message "$YELLOW" "  $0 /home             # Analyze /home directory"
    print_message "$YELLOW" "  $0 -f mb /var        # Show sizes in MB"
    print_message "$YELLOW" "  $0 -o report.txt     # Save report to file"
}

# Parse command line arguments
START_DIR="."
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -d|--depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            print_message "$RED" "Error: Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            START_DIR="$1"
            shift
            ;;
    esac
done

# Validate input directory
if [[ ! -d "$START_DIR" ]]; then
    print_message "$RED" "Error: Directory '$START_DIR' does not exist or is not accessible"
    exit 1
fi

# Check if bc is available for calculations
if ! command -v bc >/dev/null 2>&1; then
    print_message "$RED" "Error: 'bc' command is required but not installed"
    print_message "$YELLOW" "Install with: sudo apt-get install bc (Ubuntu/Debian) or brew install bc (macOS)"
    exit 1
fi

print_message "$CYAN" "Enhanced Disk Space Usage Analyzer"
print_message "$CYAN" "=================================="
print_message "$YELLOW" "Analyzing directory: $START_DIR"
print_message "$YELLOW" "Maximum depth: $MAX_DEPTH"
print_message "$YELLOW" "Output format: $OUTPUT_FORMAT"
echo ""

# Get list of subdirectories
subdirs=()
while IFS= read -r -d '' dir; do
    if [[ "$dir" != "$START_DIR" ]]; then
        subdirs+=("$dir")
    fi
done < <(find "$START_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
total_dirs=${#subdirs[@]}

if [[ $total_dirs -eq 0 ]]; then
    print_message "$YELLOW" "No subdirectories found in $START_DIR"
    exit 0
fi

# Generate reports for each directory
current=0
total_size=0

for dir in "${subdirs[@]}"; do
    ((current++))
    if [[ "$VERBOSE" == "true" ]]; then
        show_progress "$current" "$total_dirs"
    fi
    
    size=$(get_disk_usage "$dir")
    total_size=$((total_size + size))
    
    if [[ $size -gt 0 ]]; then
        generate_report "$dir"
    fi
done

if [[ "$VERBOSE" == "true" ]]; then
    echo ""  # New line after progress bar
fi

# Generate summary
print_message "$CYAN" "Summary Report"
print_message "$CYAN" "=============="
print_message "$GREEN" "Total Size: $(format_size "$total_size" "$OUTPUT_FORMAT")"
print_message "$GREEN" "Total Directories Analyzed: $total_dirs"
print_message "$GREEN" "Excluded Patterns: ${EXCLUDE_PATTERNS[*]}"

# Save report to file if requested
if [[ "$REPORT_FILE" != "" ]]; then
    {
        echo "Disk Space Usage Report"
        echo "======================"
        echo "Generated: $(date)"
        echo "Directory: $START_DIR"
        echo "Total Size: $(format_size "$total_size" "$OUTPUT_FORMAT")"
        echo "Total Directories: $total_dirs"
        echo ""
        echo "Detailed Breakdown:"
        echo "=================="
        
        for dir in "${subdirs[@]}"; do
            size=$(get_disk_usage "$dir")
            if [[ $size -gt 0 ]]; then
                echo "Directory: $dir"
                echo "Size: $(format_size "$size" "$OUTPUT_FORMAT")"
                echo ""
            fi
        done
    } > "$REPORT_FILE"
    
    print_message "$GREEN" "Report saved to: $REPORT_FILE"
fi
