#!/bin/bash
set -euo pipefail

# Generic REST API Client
# Author: Olúmáyòwá Akinkuehinmi
# Email: akintunero101@gmail.com
# Version: 1.0.0

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.config/advanced_scripts/config.conf"
readonly CACHE_DIR="${HOME}/.cache/api_client"
readonly LOG_FILE="${SCRIPT_DIR}/api_client.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Default settings
API_BASE_URL=""
API_KEY=""
TIMEOUT=30
CACHE_DURATION=300  # 5 minutes
VERBOSE=false
METHOD="GET"
HEADERS=()
DATA=""

# Function to print colored output
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_message "INFO" "Configuration loaded from $CONFIG_FILE"
    else
        log_message "WARN" "Configuration file not found: $CONFIG_FILE"
    fi
}

# Function to create cache directory
setup_cache() {
    mkdir -p "$CACHE_DIR"
}

# Function to generate cache key
get_cache_key() {
    local url="$1"
    local method="$2"
    local data="$3"
    echo -n "${method}:${url}:${data}" | md5sum | cut -d' ' -f1
}

# Function to check cache
check_cache() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/$cache_key"
    
    if [[ -f "$cache_file" ]]; then
        local cache_time=$(stat -c %Y "$cache_file")
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))
        
        if [[ $age -lt $CACHE_DURATION ]]; then
            log_message "INFO" "Cache hit for key: $cache_key"
            return 0
        else
            log_message "INFO" "Cache expired for key: $cache_key"
            rm -f "$cache_file"
        fi
    fi
    
    return 1
}

# Function to save to cache
save_cache() {
    local cache_key="$1"
    local response="$2"
    local cache_file="$CACHE_DIR/$cache_key"
    
    echo "$response" > "$cache_file"
    log_message "INFO" "Response cached with key: $cache_key"
}

# Function to validate URL
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        print_message "$RED" "Error: Invalid URL format. Must start with http:// or https://"
        return 1
    fi
    return 0
}

# Function to validate JSON
validate_json() {
    local json="$1"
    if ! echo "$json" | jq . >/dev/null 2>&1; then
        print_message "$RED" "Error: Invalid JSON format"
        return 1
    fi
    return 0
}

# Function to make API request
make_request() {
    local url="$1"
    local method="$2"
    local headers="$3"
    local data="$4"
    local use_cache="$5"
    
    # Generate cache key
    local cache_key
    cache_key=$(get_cache_key "$url" "$method" "$data")
    
    # Check cache if enabled
    if [[ "$use_cache" == "true" ]] && check_cache "$cache_key"; then
        local cache_file="$CACHE_DIR/$cache_key"
        print_message "$GREEN" "Using cached response"
        cat "$cache_file"
        return 0
    fi
    
    # Build curl command
    local curl_cmd="curl -s -w '\n%{http_code}' --connect-timeout $TIMEOUT"
    
    # Add method
    if [[ "$method" != "GET" ]]; then
        curl_cmd="$curl_cmd -X $method"
    fi
    
    # Add headers
    for header in "${HEADERS[@]}"; do
        curl_cmd="$curl_cmd -H '$header'"
    done
    
    # Add data for POST/PUT/PATCH
    if [[ -n "$data" ]] && [[ "$method" =~ ^(POST|PUT|PATCH)$ ]]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    # Add URL
    curl_cmd="$curl_cmd '$url'"
    
    # Execute request
    log_message "INFO" "Making $method request to: $url"
    if [[ "$VERBOSE" == "true" ]]; then
        print_message "$CYAN" "Executing: $curl_cmd"
    fi
    
    local response
    local http_code
    response=$(eval "$curl_cmd")
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | head -n -1)
    
    # Check HTTP status
    if [[ $http_code -ge 200 ]] && [[ $http_code -lt 300 ]]; then
        print_message "$GREEN" "Request successful (HTTP $http_code)"
        
        # Cache response if enabled
        if [[ "$use_cache" == "true" ]]; then
            save_cache "$cache_key" "$response"
        fi
        
        echo "$response"
        return 0
    else
        print_message "$RED" "Request failed (HTTP $http_code)"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "$response"
        fi
        return 1
    fi
}

# Function to format JSON output
format_json() {
    local json="$1"
    local format="$2"
    
    case $format in
        "pretty")
            echo "$json" | jq .
            ;;
        "compact")
            echo "$json" | jq -c .
            ;;
        "table")
            echo "$json" | jq -r 'to_entries[] | "\(.key): \(.value)"'
            ;;
        "raw")
            echo "$json"
            ;;
        *)
            echo "$json" | jq .
            ;;
    esac
}

# Function to show help
show_help() {
    print_message "$CYAN" "Generic REST API Client"
    print_message "$CYAN" "======================"
    echo ""
    print_message "$YELLOW" "Usage: $0 [OPTIONS] <URL>"
    echo ""
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "  -m, --method METHOD     HTTP method (GET, POST, PUT, DELETE, PATCH)"
    print_message "$YELLOW" "  -H, --header HEADER     Add custom header (can be used multiple times)"
    print_message "$YELLOW" "  -d, --data DATA         Request body data"
    print_message "$YELLOW" "  -k, --key KEY           API key for authentication"
    print_message "$YELLOW" "  -t, --timeout SECONDS   Request timeout (default: 30)"
    print_message "$YELLOW" "  -c, --cache             Enable response caching"
    print_message "$YELLOW" "  -f, --format FORMAT     Output format (pretty, compact, table, raw)"
    print_message "$YELLOW" "  -v, --verbose           Verbose output"
    print_message "$YELLOW" "  -h, --help              Show this help message"
    echo ""
    print_message "$YELLOW" "Examples:"
    print_message "$YELLOW" "  $0 https://api.example.com/users"
    print_message "$YELLOW" "  $0 -m POST -d '{\"name\":\"John\"}' https://api.example.com/users"
    print_message "$YELLOW" "  $0 -H 'Authorization: Bearer token' https://api.example.com/protected"
    print_message "$YELLOW" "  $0 -c -f table https://api.example.com/data"
    echo ""
    print_message "$YELLOW" "Environment Variables:"
    print_message "$YELLOW" "  API_BASE_URL            Default base URL for requests"
    print_message "$YELLOW" "  API_KEY                 Default API key"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--method)
                METHOD="$2"
                shift 2
                ;;
            -H|--header)
                HEADERS+=("$2")
                shift 2
                ;;
            -d|--data)
                DATA="$2"
                shift 2
                ;;
            -k|--key)
                API_KEY="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -c|--cache)
                USE_CACHE=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                print_message "$RED" "Error: Unknown option $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$URL" ]]; then
                    URL="$1"
                else
                    print_message "$RED" "Error: Multiple URLs specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Main execution
main() {
    # Load configuration
    load_config
    
    # Setup cache directory
    setup_cache
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate URL
    if [[ -z "$URL" ]]; then
        print_message "$RED" "Error: URL is required"
        show_help
        exit 1
    fi
    
    if ! validate_url "$URL"; then
        exit 1
    fi
    
    # Add API key to headers if provided
    if [[ -n "$API_KEY" ]]; then
        HEADERS+=("Authorization: Bearer $API_KEY")
    fi
    
    # Validate JSON data if provided
    if [[ -n "$DATA" ]] && ! validate_json "$DATA"; then
        exit 1
    fi
    
    # Make request
    local response
    if response=$(make_request "$URL" "$METHOD" "${HEADERS[*]}" "$DATA" "${USE_CACHE:-false}"); then
        # Format output
        format_json "$response" "${OUTPUT_FORMAT:-pretty}"
    else
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_message "$RED" "Error: Missing dependencies: ${missing_deps[*]}"
        print_message "$YELLOW" "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

# Initialize
check_dependencies
main "$@" 