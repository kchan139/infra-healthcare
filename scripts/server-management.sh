#!/bin/bash

# =============================================================================
# SERVER MANAGEMENT SCRIPTS
# =============================================================================

# -----------------------------------------------------------------------------
# System Monitoring
# -----------------------------------------------------------------------------

# Check system resources
check_resources() {
    echo "=== System Resources ==="
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')% used"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2 " (" $3/$2*100 "% used)"}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
}

# Monitor Docker containers
docker_status() {
    echo "=== Docker Containers ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo -e "\n=== Docker Resource Usage ==="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Check service logs
check_logs() {
    local service=${1:-"all"}
    if [ "$service" = "all" ]; then
        echo "=== Recent System Logs ==="
        journalctl --since "1 hour ago" --no-pager -n 20
    else
        echo "=== $service Logs ==="
        docker logs --tail 50 "$service"
    fi
}

# -----------------------------------------------------------------------------
# Docker Management
# -----------------------------------------------------------------------------

# Clean up Docker resources
docker_cleanup() {
    echo "Cleaning up Docker resources..."
    docker system prune -f
    docker volume prune -f
    docker image prune -f
    echo "Cleanup complete."
}

# Restart all services
restart_services() {
    echo "Restarting Docker services..."
    docker compose down
    sleep 5
    docker compose up -d
    echo "Services restarted."
}

# Update and deploy services
deploy_services() {
    echo "Deploying latest services..."
    docker compose pull
    docker compose up -d --remove-orphans
    echo "Deployment complete."
}

# -----------------------------------------------------------------------------
# System Maintenance
# -----------------------------------------------------------------------------

# Update system packages
update_system() {
    echo "Updating system packages..."
    apt update && apt upgrade -y
    apt autoremove -y
    echo "System updated."
}

# Backup configuration files
backup_configs() {
    local backup_dir="/opt/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    echo "Backing up configurations to $backup_dir..."
    cp -r /opt/app/config "$backup_dir/"
    cp docker compose.yml "$backup_dir/"

    # Keep only last 7 days of backups
    find /opt/backups -type d -mtime +7 -exec rm -rf {} \;
    echo "Backup completed."
}

# Check disk space and clean if needed
disk_maintenance() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "Disk usage: ${usage}%"

    if [ "$usage" -gt 80 ]; then
        echo "Disk usage high, cleaning up..."
        docker_cleanup
        apt autoremove -y
        apt autoclean
        journalctl --vacuum-time=7d
        echo "Cleanup completed."
    fi
}

# -----------------------------------------------------------------------------
# Health Checks
# -----------------------------------------------------------------------------

# Check service health
health_check() {
    echo "=== Service Health Check ==="

    # Check Docker daemon
    if systemctl is-active --quiet docker; then
        echo "✓ Docker: Running"
    else
        echo "✗ Docker: Not running"
    fi

    # Check services
    for service in $(docker compose ps --services); do
        if [ "$(docker compose ps -q $service)" ]; then
            echo "✓ $service: Running"
        else
            echo "✗ $service: Not running"
        fi
    done

    # Check ports
    for port in 80 443 3000 8080; do
        if netstat -tuln | grep -q ":$port "; then
            echo "✓ Port $port: Open"
        else
            echo "✗ Port $port: Closed"
        fi
    done
}

# Test connectivity
connectivity_test() {
    echo "=== Connectivity Test ==="

    # Test external connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        echo "✓ External connectivity: OK"
    else
        echo "✗ External connectivity: Failed"
    fi

    # Test database connection (if applicable)
    if docker exec postgres-container pg_isready >/dev/null 2>&1; then
        echo "✓ Database: Connected"
    else
        echo "✗ Database: Connection failed"
    fi
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Show quick system overview
overview() {
    neofetch
    echo ""
    docker_status
}

# Show help
show_help() {
    echo "Server Management Scripts"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  overview          - System overview"
    echo "  resources         - Check system resources"
    echo "  docker            - Docker container status"
    echo "  logs [service]    - Show logs (service name or 'all')"
    echo "  health            - Health check all services"
    echo "  connectivity      - Test network connectivity"
    echo "  cleanup           - Clean up Docker resources"
    echo "  restart           - Restart all services"
    echo "  deploy            - Deploy latest services"
    echo "  update            - Update system packages"
    echo "  backup            - Backup configurations"
    echo "  maintenance       - Disk maintenance"
    echo "  help              - Show this help"
}

# -----------------------------------------------------------------------------
# Main Script Logic
# -----------------------------------------------------------------------------

case "$1" in
    overview)       overview ;;
    resources)      check_resources ;;
    docker)         docker_status ;;
    logs)           check_logs "$2" ;;
    health)         health_check ;;
    connectivity)   connectivity_test ;;
    cleanup)        docker_cleanup ;;
    restart)        restart_services ;;
    deploy)         deploy_services ;;
    update)         update_system ;;
    backup)         backup_configs ;;
    maintenance)    disk_maintenance ;;
    help|--help|-h) show_help ;;
    *)              show_help ;;
esac
