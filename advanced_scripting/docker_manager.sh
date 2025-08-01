#!/bin/bash
set -euo pipefail

# Docker Management Script
# Author: Olúmáyòwá Akinkuehinmi
# Email: akintunero101@gmail.com
# Version: 1.0.0

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.config/advanced_scripts/config.conf"
readonly LOG_FILE="${SCRIPT_DIR}/docker_manager.log"
readonly BACKUP_DIR="${SCRIPT_DIR}/backups"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Default settings
VERBOSE=false
DRY_RUN=false
FORCE=false
BACKUP_ENABLED=true
CLEANUP_ENABLED=false

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

# Function to check Docker availability
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        print_message "$RED" "Error: Docker is not installed or not in PATH"
        print_message "$YELLOW" "Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_message "$RED" "Error: Docker daemon is not running or you don't have permissions"
        print_message "$YELLOW" "Start Docker daemon or add user to docker group"
        exit 1
    fi
    
    log_message "INFO" "Docker is available and running"
}

# Function to get container information
get_container_info() {
    local container_id="$1"
    docker inspect "$container_id" 2>/dev/null || echo "{}"
}

# Function to get container status
get_container_status() {
    local container_id="$1"
    docker ps --filter "id=$container_id" --format "table {{.Status}}" 2>/dev/null | tail -n +2
}

# Function to list containers
list_containers() {
    local filter="${1:-}"
    local format="${2:-table}"
    
    case $format in
        "table")
            if [[ -n "$filter" ]]; then
                docker ps -a --filter "$filter" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
            else
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
            fi
            ;;
        "json")
            if [[ -n "$filter" ]]; then
                docker ps -a --filter "$filter" --format "json"
            else
                docker ps -a --format "json"
            fi
            ;;
        "id")
            if [[ -n "$filter" ]]; then
                docker ps -aq --filter "$filter"
            else
                docker ps -aq
            fi
            ;;
        *)
            print_message "$RED" "Error: Unknown format '$format'"
            return 1
            ;;
    esac
}

# Function to start containers
start_containers() {
    local containers="$1"
    local failed=()
    
    print_message "$BLUE" "Starting containers..."
    
    for container in $containers; do
        if [[ "$DRY_RUN" == "true" ]]; then
            print_message "$YELLOW" "DRY RUN: Would start container $container"
        else
            if docker start "$container" >/dev/null 2>&1; then
                print_message "$GREEN" "Started container: $container"
                log_message "INFO" "Started container: $container"
            else
                print_message "$RED" "Failed to start container: $container"
                failed+=("$container")
                log_message "ERROR" "Failed to start container: $container"
            fi
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_message "$RED" "Failed to start ${#failed[@]} containers: ${failed[*]}"
        return 1
    fi
    
    return 0
}

# Function to stop containers
stop_containers() {
    local containers="$1"
    local failed=()
    
    print_message "$BLUE" "Stopping containers..."
    
    for container in $containers; do
        if [[ "$DRY_RUN" == "true" ]]; then
            print_message "$YELLOW" "DRY RUN: Would stop container $container"
        else
            if docker stop "$container" >/dev/null 2>&1; then
                print_message "$GREEN" "Stopped container: $container"
                log_message "INFO" "Stopped container: $container"
            else
                print_message "$RED" "Failed to stop container: $container"
                failed+=("$container")
                log_message "ERROR" "Failed to stop container: $container"
            fi
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_message "$RED" "Failed to stop ${#failed[@]} containers: ${failed[*]}"
        return 1
    fi
    
    return 0
}

# Function to restart containers
restart_containers() {
    local containers="$1"
    local failed=()
    
    print_message "$BLUE" "Restarting containers..."
    
    for container in $containers; do
        if [[ "$DRY_RUN" == "true" ]]; then
            print_message "$YELLOW" "DRY RUN: Would restart container $container"
        else
            if docker restart "$container" >/dev/null 2>&1; then
                print_message "$GREEN" "Restarted container: $container"
                log_message "INFO" "Restarted container: $container"
            else
                print_message "$RED" "Failed to restart container: $container"
                failed+=("$container")
                log_message "ERROR" "Failed to restart container: $container"
            fi
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_message "$RED" "Failed to restart ${#failed[@]} containers: ${failed[*]}"
        return 1
    fi
    
    return 0
}

# Function to remove containers
remove_containers() {
    local containers="$1"
    local failed=()
    
    print_message "$BLUE" "Removing containers..."
    
    for container in $containers; do
        if [[ "$DRY_RUN" == "true" ]]; then
            print_message "$YELLOW" "DRY RUN: Would remove container $container"
        else
            local force_flag=""
            if [[ "$FORCE" == "true" ]]; then
                force_flag="-f"
            fi
            
            if docker rm $force_flag "$container" >/dev/null 2>&1; then
                print_message "$GREEN" "Removed container: $container"
                log_message "INFO" "Removed container: $container"
            else
                print_message "$RED" "Failed to remove container: $container"
                failed+=("$container")
                log_message "ERROR" "Failed to remove container: $container"
            fi
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_message "$RED" "Failed to remove ${#failed[@]} containers: ${failed[*]}"
        return 1
    fi
    
    return 0
}

# Function to backup container data
backup_container() {
    local container_id="$1"
    local backup_name="${2:-container_$(date +%Y%m%d_%H%M%S)}"
    local backup_path="$BACKUP_DIR/$backup_name.tar"
    
    if [[ "$BACKUP_ENABLED" != "true" ]]; then
        print_message "$YELLOW" "Backup disabled, skipping..."
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_message "$YELLOW" "DRY RUN: Would backup container $container_id to $backup_path"
    else
        if docker export "$container_id" > "$backup_path" 2>/dev/null; then
            print_message "$GREEN" "Backed up container $container_id to $backup_path"
            log_message "INFO" "Backed up container $container_id to $backup_path"
        else
            print_message "$RED" "Failed to backup container $container_id"
            log_message "ERROR" "Failed to backup container $container_id"
            return 1
        fi
    fi
    
    return 0
}

# Function to cleanup unused resources
cleanup_resources() {
    if [[ "$CLEANUP_ENABLED" != "true" ]]; then
        print_message "$YELLOW" "Cleanup disabled, skipping..."
        return 0
    fi
    
    print_message "$BLUE" "Cleaning up unused Docker resources..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_message "$YELLOW" "DRY RUN: Would run docker system prune"
    else
        if docker system prune -f >/dev/null 2>&1; then
            print_message "$GREEN" "Cleaned up unused Docker resources"
            log_message "INFO" "Cleaned up unused Docker resources"
        else
            print_message "$RED" "Failed to cleanup Docker resources"
            log_message "ERROR" "Failed to cleanup Docker resources"
            return 1
        fi
    fi
    
    return 0
}

# Function to monitor containers
monitor_containers() {
    local containers="$1"
    local interval="${2:-5}"
    
    print_message "$BLUE" "Monitoring containers (refresh every ${interval}s)..."
    print_message "$YELLOW" "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        print_message "$CYAN" "Container Status - $(date)"
        print_message "$CYAN" "=================================="
        
        for container in $containers; do
            local status
            status=$(get_container_status "$container")
            local name
            name=$(docker inspect --format '{{.Name}}' "$container" 2>/dev/null || echo "Unknown")
            
            if [[ -n "$status" ]]; then
                print_message "$GREEN" "$name: $status"
            else
                print_message "$RED" "$name: Not running"
            fi
        done
        
        sleep "$interval"
    done
}

# Function to show container logs
show_logs() {
    local container="$1"
    local lines="${2:-50}"
    local follow="${3:-false}"
    
    local follow_flag=""
    if [[ "$follow" == "true" ]]; then
        follow_flag="-f"
    fi
    
    print_message "$BLUE" "Showing logs for container: $container"
    docker logs --tail "$lines" $follow_flag "$container" 2>/dev/null || {
        print_message "$RED" "Failed to get logs for container: $container"
        return 1
    }
}

# Function to show help
show_help() {
    print_message "$CYAN" "Docker Management Script"
    print_message "$CYAN" "======================"
    echo ""
    print_message "$YELLOW" "Usage: $0 [OPTIONS] COMMAND [ARGS...]"
    echo ""
    print_message "$YELLOW" "Commands:"
    print_message "$YELLOW" "  list [FILTER]           List containers (with optional filter)"
    print_message "$YELLOW" "  start CONTAINER...      Start containers"
    print_message "$YELLOW" "  stop CONTAINER...       Stop containers"
    print_message "$YELLOW" "  restart CONTAINER...    Restart containers"
    print_message "$YELLOW" "  remove CONTAINER...     Remove containers"
    print_message "$YELLOW" "  backup CONTAINER [NAME] Backup container data"
    print_message "$YELLOW" "  cleanup                 Clean up unused resources"
    print_message "$YELLOW" "  monitor CONTAINER...    Monitor container status"
    print_message "$YELLOW" "  logs CONTAINER [LINES]  Show container logs"
    echo ""
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "  -v, --verbose           Verbose output"
    print_message "$YELLOW" "  -d, --dry-run          Show what would be done without doing it"
    print_message "$YELLOW" "  -f, --force            Force removal of containers"
    print_message "$YELLOW" "  --no-backup            Disable automatic backups"
    print_message "$YELLOW" "  --cleanup              Enable automatic cleanup"
    print_message "$YELLOW" "  -h, --help             Show this help message"
    echo ""
    print_message "$YELLOW" "Examples:"
    print_message "$YELLOW" "  $0 list"
    print_message "$YELLOW" "  $0 start container1 container2"
    print_message "$YELLOW" "  $0 stop --filter 'status=exited'"
    print_message "$YELLOW" "  $0 monitor container1 container2"
    print_message "$YELLOW" "  $0 logs container1 100"
    echo ""
    print_message "$YELLOW" "Filters:"
    print_message "$YELLOW" "  status=running          Running containers"
    print_message "$YELLOW" "  status=exited           Exited containers"
    print_message "$YELLOW" "  label=environment=prod  Containers with specific label"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --no-backup)
                BACKUP_ENABLED=false
                shift
                ;;
            --cleanup)
                CLEANUP_ENABLED=true
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
                break
                ;;
        esac
    done
    
    # Get command and arguments
    if [[ $# -eq 0 ]]; then
        print_message "$RED" "Error: Command is required"
        show_help
        exit 1
    fi
    
    COMMAND="$1"
    shift
    ARGS=("$@")
}

# Main execution
main() {
    # Load configuration
    load_config
    
    # Check Docker availability
    check_docker
    
    # Parse arguments
    parse_arguments "$@"
    
    # Execute command
    case $COMMAND in
        list)
            local filter="${ARGS[0]:-}"
            local format="${ARGS[1]:-table}"
            list_containers "$filter" "$format"
            ;;
        start)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name(s) required"
                exit 1
            fi
            start_containers "${ARGS[*]}"
            ;;
        stop)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name(s) required"
                exit 1
            fi
            stop_containers "${ARGS[*]}"
            ;;
        restart)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name(s) required"
                exit 1
            fi
            restart_containers "${ARGS[*]}"
            ;;
        remove)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name(s) required"
                exit 1
            fi
            remove_containers "${ARGS[*]}"
            ;;
        backup)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name required"
                exit 1
            fi
            local container="${ARGS[0]}"
            local backup_name="${ARGS[1]:-}"
            backup_container "$container" "$backup_name"
            ;;
        cleanup)
            cleanup_resources
            ;;
        monitor)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name(s) required"
                exit 1
            fi
            local containers="${ARGS[*]}"
            local interval="${ARGS[-1]:-5}"
            monitor_containers "$containers" "$interval"
            ;;
        logs)
            if [[ ${#ARGS[@]} -eq 0 ]]; then
                print_message "$RED" "Error: Container name required"
                exit 1
            fi
            local container="${ARGS[0]}"
            local lines="${ARGS[1]:-50}"
            local follow="${ARGS[2]:-false}"
            show_logs "$container" "$lines" "$follow"
            ;;
        *)
            print_message "$RED" "Error: Unknown command '$COMMAND'"
            show_help
            exit 1
            ;;
    esac
}

# Initialize
main "$@" 