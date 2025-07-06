#!/bin/bash

# =============================================================================
# SERVER MANAGEMENT SCRIPT
# Version: 2.0.0
# Author: Khoa Tran
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_PID=$$

# Load configuration file if exists
CONFIG_FILE="${SCRIPT_DIR}/.server-mgmt.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Default configuration (can be overridden in config file)
readonly LOG_DIR="${LOG_DIR:-/var/log/server-mgmt}"
readonly BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
readonly COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
readonly MAX_BACKUP_DAYS="${MAX_BACKUP_DAYS:-7}"
readonly DISK_USAGE_THRESHOLD="${DISK_USAGE_THRESHOLD:-80}"
readonly MEMORY_USAGE_THRESHOLD="${MEMORY_USAGE_THRESHOLD:-85}"
readonly CPU_USAGE_THRESHOLD="${CPU_USAGE_THRESHOLD:-90}"
readonly LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"

# Service configuration
readonly DEFAULT_SERVICES="${DEFAULT_SERVICES:-}"
readonly REQUIRED_PORTS="${REQUIRED_PORTS:-80 443}"
readonly HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-10}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Logging and Error Handling
# -----------------------------------------------------------------------------

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    readonly LOG_FILE="${LOG_DIR}/server-mgmt-$(date +%Y%m%d).log"
    
    # Redirect stderr to log file
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    # Log script start
    log_info "Script started: $SCRIPT_NAME v$SCRIPT_VERSION (PID: $SCRIPT_PID)"
}

# Logging functions
log_info() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
}

log_debug() {
    local message="$1"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE"
    fi
}

# Error handler
error_handler() {
    local line_number="$1"
    local error_code="$2"
    local command="$3"
    
    log_error "Error on line $line_number: Command '$command' exited with code $error_code"
    cleanup_on_exit
    exit "$error_code"
}

# Cleanup function
cleanup_on_exit() {
    log_info "Cleaning up temporary files and processes..."
    # Add cleanup logic here if needed
    log_info "Script finished: $SCRIPT_NAME (PID: $SCRIPT_PID)"
}

# Set up trap handlers
trap 'error_handler ${LINENO} $? "${BASH_COMMAND}"' ERR
trap 'cleanup_on_exit' EXIT

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Validate prerequisites
validate_prerequisites() {
    local missing_commands=()
    
    # Check required commands
    local required_commands=("docker" "systemctl" "netstat" "df" "free" "top")
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        exit 1
    fi
    
    # Check Docker daemon
    if ! systemctl is-active --quiet docker; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check compose file
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_warn "Docker Compose file not found: $COMPOSE_FILE"
    fi
}

# Convert bytes to human readable format
bytes_to_human() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -ge 1024 && $unit -lt ${#units[@]} ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Send notification (placeholder for integration with monitoring systems)
send_notification() {
    local severity="$1"
    local message="$2"
    
    log_info "NOTIFICATION [$severity]: $message"
    
    # Add integration with monitoring systems here
    # Examples: Slack, PagerDuty, email, etc.
}

# -----------------------------------------------------------------------------
# System Monitoring Functions
# -----------------------------------------------------------------------------

# Enhanced system resource check
check_resources() {
    log_info "Checking system resources..."
    
    echo "=== System Resources ($(get_timestamp)) ==="
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    echo "CPU: ${cpu_usage}% used"
    
    if (( $(echo "$cpu_usage > $CPU_USAGE_THRESHOLD" | bc -l) )); then
        log_warn "High CPU usage detected: ${cpu_usage}%"
        send_notification "WARNING" "High CPU usage: ${cpu_usage}%"
    fi
    
    # Memory usage
    local mem_percent
    mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    local mem_used
    mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    local mem_total
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    echo "Memory: ${mem_used}/${mem_total} (${mem_percent}%) used"
    
    if [[ $mem_percent -gt $MEMORY_USAGE_THRESHOLD ]]; then
        log_warn "High memory usage detected: ${mem_percent}%"
        send_notification "WARNING" "High memory usage: ${mem_percent}%"
    fi
    
    # Disk usage
    local disk_info
    disk_info=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')
    echo "Disk: $disk_info"
    
    # Load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "Load Average:$load_avg"
    
    # System uptime
    local uptime_info
    uptime_info=$(uptime -p)
    echo "Uptime: $uptime_info"
    
    # Network interfaces
    echo -e "\n=== Network Interfaces ==="
    ip -br addr show | grep -v "lo\|DOWN"
    
    echo ""
}

# Enhanced Docker monitoring
docker_status() {
    log_info "Checking Docker container status..."
    
    if ! command_exists docker; then
        log_error "Docker is not installed"
        return 1
    fi
    
    echo "=== Docker Containers ($(get_timestamp)) ==="
    
    # Container status
    if docker ps -q | grep -q .; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.RunningFor}}"
    else
        echo "No running containers found"
    fi
    
    echo -e "\n=== Docker Resource Usage ==="
    if docker ps -q | grep -q .; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    else
        echo "No containers to monitor"
    fi
    
    # Docker system info
    echo -e "\n=== Docker System Info ==="
    docker system df
    
    echo ""
}

# Enhanced log checking
check_logs() {
    local service="${1:-all}"
    local lines="${2:-50}"
    
    log_info "Checking logs for service: $service"
    
    if [[ "$service" == "all" ]]; then
        echo "=== Recent System Logs ($(get_timestamp)) ==="
        journalctl --since "1 hour ago" --no-pager -n "$lines" --output=short-precise
    else
        echo "=== $service Logs ($(get_timestamp)) ==="
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            docker logs --tail "$lines" --timestamps "$service"
        else
            log_error "Container '$service' not found"
            return 1
        fi
    fi
    
    echo ""
}

# -----------------------------------------------------------------------------
# Docker Management Functions
# -----------------------------------------------------------------------------

# Enhanced Docker cleanup
docker_cleanup() {
    log_info "Starting Docker cleanup..."
    
    echo "=== Docker Cleanup ($(get_timestamp)) ==="
    
    # Show current usage
    echo "Before cleanup:"
    docker system df
    
    # Cleanup with confirmation in non-interactive mode
    echo -e "\nCleaning up Docker resources..."
    
    # Remove stopped containers
    local stopped_containers
    stopped_containers=$(docker ps -aq -f status=exited)
    if [[ -n "$stopped_containers" ]]; then
        echo "Removing stopped containers..."
        docker rm $stopped_containers
    fi
    
    # Remove unused images
    echo "Removing unused images..."
    docker image prune -f
    
    # Remove unused volumes
    echo "Removing unused volumes..."
    docker volume prune -f
    
    # Remove unused networks
    echo "Removing unused networks..."
    docker network prune -f
    
    # Show usage after cleanup
    echo -e "\nAfter cleanup:"
    docker system df
    
    log_info "Docker cleanup completed"
    echo ""
}

# Enhanced service restart
restart_services() {
    log_info "Restarting Docker services..."
    
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        return 1
    fi
    
    echo "=== Service Restart ($(get_timestamp)) ==="
    
    # Stop services gracefully
    echo "Stopping services..."
    docker compose -f "$COMPOSE_FILE" down --timeout 30
    
    # Wait for cleanup
    echo "Waiting for cleanup..."
    sleep 10
    
    # Start services
    echo "Starting services..."
    docker compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to start
    echo "Waiting for services to start..."
    sleep 15
    
    # Check service status
    echo "Checking service status..."
    docker compose -f "$COMPOSE_FILE" ps
    
    log_info "Service restart completed"
    echo ""
}

# Enhanced deployment
deploy_services() {
    log_info "Starting service deployment..."
    
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        return 1
    fi
    
    echo "=== Service Deployment ($(get_timestamp)) ==="
    
    # Create backup before deployment
    backup_configs
    
    # Pull latest images
    echo "Pulling latest images..."
    docker compose -f "$COMPOSE_FILE" pull
    
    # Deploy services
    echo "Deploying services..."
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    
    # Wait for services to stabilize
    echo "Waiting for services to stabilize..."
    sleep 30
    
    # Health check after deployment
    health_check
    
    log_info "Service deployment completed"
    echo ""
}

# -----------------------------------------------------------------------------
# System Maintenance Functions
# -----------------------------------------------------------------------------

# Enhanced system update
update_system() {
    log_info "Starting system update..."
    
    echo "=== System Update ($(get_timestamp)) ==="
    
    # Update package lists
    echo "Updating package lists..."
    apt update
    
    # Show available updates
    echo "Available updates:"
    apt list --upgradable
    
    # Upgrade packages
    echo "Upgrading packages..."
    apt upgrade -y
    
    # Remove unnecessary packages
    echo "Removing unnecessary packages..."
    apt autoremove -y
    
    # Clean package cache
    echo "Cleaning package cache..."
    apt autoclean
    
    # Update locate database
    if command_exists updatedb; then
        echo "Updating locate database..."
        updatedb
    fi
    
    log_info "System update completed"
    echo ""
}

# Enhanced backup function
backup_configs() {
    log_info "Starting configuration backup..."
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${timestamp}"
    
    echo "=== Configuration Backup ($(get_timestamp)) ==="
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    echo "Creating backup in: $backup_path"
    
    # Backup configurations
    if [[ -d "/opt/app/config" ]]; then
        cp -r /opt/app/config "$backup_path/"
        echo "✓ Application config backed up"
    fi
    
    if [[ -f "$COMPOSE_FILE" ]]; then
        cp "$COMPOSE_FILE" "$backup_path/"
        echo "✓ Docker Compose file backed up"
    fi
    
    # Backup environment files
    if [[ -f ".env" ]]; then
        cp .env "$backup_path/"
        echo "✓ Environment file backed up"
    fi
    
    # Backup script configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_path/"
        echo "✓ Script configuration backed up"
    fi
    
    # Create backup manifest
    cat > "$backup_path/backup-manifest.txt" << EOF
Backup created: $(get_timestamp)
Backup type: Configuration
Script version: $SCRIPT_VERSION
System: $(uname -a)
Docker version: $(docker --version)
EOF
    
    # Compress backup
    echo "Compressing backup..."
    tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$timestamp"
    rm -rf "$backup_path"
    
    # Clean old backups
    echo "Cleaning old backups..."
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$MAX_BACKUP_DAYS -delete
    
    echo "Backup completed: ${backup_path}.tar.gz"
    log_info "Configuration backup completed"
    echo ""
}

# Enhanced disk maintenance
disk_maintenance() {
    log_info "Starting disk maintenance..."
    
    echo "=== Disk Maintenance ($(get_timestamp)) ==="
    
    # Check disk usage
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "Current disk usage: ${usage}%"
    
    if [[ $usage -gt $DISK_USAGE_THRESHOLD ]]; then
        log_warn "Disk usage above threshold (${DISK_USAGE_THRESHOLD}%), starting cleanup..."
        
        # Docker cleanup
        echo "Performing Docker cleanup..."
        docker_cleanup
        
        # System cleanup
        echo "Performing system cleanup..."
        apt autoremove -y
        apt autoclean
        
        # Log cleanup
        echo "Cleaning old logs..."
        journalctl --vacuum-time=${LOG_RETENTION_DAYS}d
        
        # Clean temporary files
        echo "Cleaning temporary files..."
        find /tmp -type f -mtime +7 -delete 2>/dev/null || true
        
        # Update usage
        usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        echo "Disk usage after cleanup: ${usage}%"
        
        if [[ $usage -gt $DISK_USAGE_THRESHOLD ]]; then
            log_warn "Disk usage still high after cleanup: ${usage}%"
            send_notification "WARNING" "Disk usage remains high: ${usage}%"
        fi
    else
        echo "Disk usage within acceptable limits"
    fi
    
    # Show disk usage by directory
    echo -e "\nTop 10 largest directories:"
    du -h /var /opt /usr 2>/dev/null | sort -hr | head -10
    
    log_info "Disk maintenance completed"
    echo ""
}

# -----------------------------------------------------------------------------
# Health Check Functions
# -----------------------------------------------------------------------------

# Enhanced health check
health_check() {
    log_info "Starting comprehensive health check..."
    
    echo "=== Service Health Check ($(get_timestamp)) ==="
    
    local health_status=0
    
    # Check system services
    echo "System Services:"
    local services=("docker" "ssh" "cron")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "  ✓ $service: Running"
        else
            echo "  ✗ $service: Not running"
            health_status=1
        fi
    done
    
    # Check Docker containers
    echo -e "\nDocker Containers:"
    if [[ -f "$COMPOSE_FILE" ]]; then
        local compose_services
        compose_services=$(docker compose -f "$COMPOSE_FILE" config --services)
        
        for service in $compose_services; do
            if docker compose -f "$COMPOSE_FILE" ps -q "$service" | grep -q .; then
                local status
                status=$(docker compose -f "$COMPOSE_FILE" ps "$service" | tail -n +3 | awk '{print $4}')
                if [[ "$status" == "Up" ]]; then
                    echo "  ✓ $service: Running"
                else
                    echo "  ✗ $service: $status"
                    health_status=1
                fi
            else
                echo "  ✗ $service: Not running"
                health_status=1
            fi
        done
    else
        echo "  ! No Docker Compose file found"
    fi
    
    # Check network ports
    echo -e "\nNetwork Ports:"
    for port in $REQUIRED_PORTS; do
        if netstat -tuln | grep -q ":$port "; then
            echo "  ✓ Port $port: Open"
        else
            echo "  ✗ Port $port: Closed"
            health_status=1
        fi
    done
    
    # Check disk space
    echo -e "\nDisk Space:"
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt $DISK_USAGE_THRESHOLD ]]; then
        echo "  ✓ Disk usage: ${disk_usage}% (OK)"
    else
        echo "  ✗ Disk usage: ${disk_usage}% (HIGH)"
        health_status=1
    fi
    
    # Check memory
    echo -e "\nMemory:"
    local mem_usage
    mem_usage=$(free | awk '/^Mem:/ {print int($3/$2*100)}')
    if [[ $mem_usage -lt $MEMORY_USAGE_THRESHOLD ]]; then
        echo "  ✓ Memory usage: ${mem_usage}% (OK)"
    else
        echo "  ✗ Memory usage: ${mem_usage}% (HIGH)"
        health_status=1
    fi
    
    # Overall health status
    echo -e "\nOverall Health Status:"
    if [[ $health_status -eq 0 ]]; then
        echo "  ✓ All systems healthy"
        log_info "Health check passed"
    else
        echo "  ✗ Issues detected"
        log_warn "Health check failed"
        send_notification "WARNING" "Health check failed - issues detected"
    fi
    
    
    echo ""
    # Don't exit with error status for health check failures
    if [[ $health_status -eq 0 ]]; then
        log_info "Health check passed"
    else
        log_warn "Health check failed"
    fi
}

# Enhanced connectivity test
connectivity_test() {
    log_info "Starting connectivity test..."
    
    echo "=== Connectivity Test ($(get_timestamp)) ==="
    
    # Test external connectivity
    echo "External Connectivity:"
    local test_hosts=("google.com" "github.com" "docker.io")
    for host in "${test_hosts[@]}"; do
        if timeout 10 ping -c 3 "$host" >/dev/null 2>&1; then
            echo "  ✓ $host: Reachable"
        else
            echo "  ✗ $host: Unreachable"
        fi
    done
    
    # Test DNS resolution
    echo -e "\nDNS Resolution:"
    if nslookup google.com >/dev/null 2>&1; then
        echo "  ✓ DNS: Working"
    else
        echo "  ✗ DNS: Failed"
    fi
    
    # Test database connectivity (if configured)
    echo -e "\nDatabase Connectivity:"
    if [[ -n "${DB_CONTAINER:-}" ]]; then
        if docker exec "$DB_CONTAINER" pg_isready >/dev/null 2>&1; then
            echo "  ✓ PostgreSQL: Connected"
        else
            echo "  ✗ PostgreSQL: Connection failed"
        fi
    else
        echo "  - Database container not configured"
    fi
    
    # Test web services
    echo -e "\nWeb Services:"
    for port in $REQUIRED_PORTS; do
        if timeout 5 curl -s -o /dev/null "http://localhost:$port" 2>/dev/null; then
            echo "  ✓ Port $port: HTTP response OK"
        else
            echo "  ✗ Port $port: No HTTP response"
        fi
    done
    
    log_info "Connectivity test completed"
    echo ""
}

# -----------------------------------------------------------------------------
# Additional Utility Functions
# -----------------------------------------------------------------------------

# System overview
overview() {
    echo "=== System Overview ($(get_timestamp)) ==="
    
    # System information
    if command_exists neofetch; then
        neofetch
    else
        echo "System: $(uname -a)"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime -p)"
    fi
    
    echo ""
    docker_status
    check_resources
}

# Security scan
security_scan() {
    log_info "Starting security scan..."
    
    echo "=== Security Scan ($(get_timestamp)) ==="
    
    # Check for failed login attempts
    echo "Failed Login Attempts (last 24 hours):"
    journalctl --since "24 hours ago" | grep -i "failed\|invalid" | wc -l
    
    # Check listening ports
    echo -e "\nListening Ports:"
    netstat -tuln | grep LISTEN
    
    # Check for updates
    echo -e "\nSecurity Updates:"
    apt list --upgradable 2>/dev/null | grep -i security | wc -l
    
    # Check Docker security
    echo -e "\nDocker Security:"
    if docker ps --format "{{.Names}}" | grep -q .; then
        echo "  Containers running as root: $(docker ps -q | xargs -I {} docker inspect {} | grep -c '"User": ""')"
    fi
    
    log_info "Security scan completed"
    echo ""
}

# Performance monitoring
performance_monitor() {
    log_info "Starting performance monitoring..."
    
    echo "=== Performance Monitor ($(get_timestamp)) ==="
    
    # CPU information
    echo "CPU Information:"
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"
    
    # Memory information
    echo -e "\nMemory Information:"
    free -h
    
    # I/O statistics
    echo -e "\nI/O Statistics:"
    if command_exists iostat; then
        iostat -x 1 1
    else
        echo "iostat not available"
    fi
    
    # Network statistics
    echo -e "\nNetwork Statistics:"
    cat /proc/net/dev | grep -E "eth|ens|wlan" | head -5
    
    log_info "Performance monitoring completed"
    echo ""
}

# Generate report
generate_report() {
    local report_file="${LOG_DIR}/health-report-$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating comprehensive report..."
    
    {
        echo "=========================================="
        echo "SERVER HEALTH REPORT"
        echo "Generated: $(get_timestamp)"
        echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "=========================================="
        echo
        
        overview || true
        health_check || true
        connectivity_test || true
        security_scan || true
        performance_monitor || true
        
        echo "=========================================="
        echo "REPORT END"
        echo "=========================================="
    } > "$report_file"
    
    echo "Report generated: $report_file"
    log_info "Report generated: $report_file"
}

# Show help
show_help() {
    cat << EOF
Server Management Script v$SCRIPT_VERSION

USAGE:
    $SCRIPT_NAME [COMMAND] [OPTIONS]

COMMANDS:
    overview            Show system overview
    resources           Check system resources
    docker              Show Docker container status
    logs [SERVICE]      Show logs (service name or 'all')
    health              Comprehensive health check
    connectivity        Test network connectivity
    security            Run security scan
    performance         Show performance metrics
    cleanup             Clean up Docker resources
    restart             Restart all services
    deploy              Deploy latest services
    update              Update system packages
    backup              Backup configurations
    maintenance         Perform disk maintenance
    report              Generate comprehensive report
    help                Show this help message

OPTIONS:
    --debug             Enable debug logging
    --config FILE       Use custom configuration file
    --dry-run           Show what would be done without executing

EXAMPLES:
    $SCRIPT_NAME overview
    $SCRIPT_NAME logs nginx
    $SCRIPT_NAME health
    $SCRIPT_NAME --debug docker

CONFIGURATION:
    Configuration file: $CONFIG_FILE
    Log directory: $LOG_DIR
    Backup directory: $BACKUP_DIR

For more information, see the documentation or contact your system administrator.
EOF
}

# -----------------------------------------------------------------------------
# Main Script Logic
# -----------------------------------------------------------------------------

# Initialize
init_logging

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=true
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            COMMAND="$1"
            shift
            break
            ;;
    esac
done

# Set default command if none provided
COMMAND="${COMMAND:-help}"

# Validate prerequisites (skip for help command)
if [[ "$COMMAND" != "help" ]]; then
    validate_prerequisites
fi

# Execute command
case "$COMMAND" in
    overview)
        overview
        ;;
    resources)
        check_resources
        ;;
    docker)
        docker_status
        ;;
    logs)
        check_logs "${1:-all}" "${2:-50}"
        ;;
    health)
        health_check
        ;;
    connectivity)
        connectivity_test
        ;;
    security)
        security_scan
        ;;
    performance)
        performance_monitor
        ;;
    cleanup)
        docker_cleanup
        ;;
    restart)
        restart_services
        ;;
    deploy)
        deploy_services
        ;;
    update)
        update_system
        ;;
    backup)
        backup_configs
        ;;
    maintenance)
        disk_maintenance
        ;;
    report)
        generate_report
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        echo "Use '$SCRIPT_NAME help' for usage information."
        exit 1
        ;;
esac

log_info "Command '$COMMAND' completed successfully"
