#!/bin/bash

# FiveM Server Management Script
# This script helps manage the FiveM server after deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Get VM connection info
get_connection_info() {
    if [ ! -f "terraform.tfstate" ]; then
        print_error "No terraform.tfstate found. Deploy the infrastructure first."
        exit 1
    fi
    
    VM_IP=$(terraform output -raw vm_public_ip 2>/dev/null)
    ADMIN_USER=$(terraform output -raw admin_username 2>/dev/null || echo "azureuser")
    
    if [ -z "$VM_IP" ]; then
        print_error "Could not get VM IP from terraform output."
        exit 1
    fi
    
    print_status "VM IP: $VM_IP"
    print_status "Admin User: $ADMIN_USER"
}

# SSH to the VM
ssh_to_vm() {
    get_connection_info
    print_status "Connecting to FiveM server VM..."
    ssh "$ADMIN_USER@$VM_IP"
}

# Check server status
check_status() {
    get_connection_info
    print_status "Checking FiveM server status..."
    ssh "$ADMIN_USER@$VM_IP" << 'EOF'
        echo "=== System Status ==="
        sudo systemctl is-active fivem && echo "FiveM service: ACTIVE" || echo "FiveM service: INACTIVE"
        
        if [ -f /mnt/fivem-server/fivem.pid ]; then
            PID=$(cat /mnt/fivem-server/fivem.pid)
            if ps -p $PID > /dev/null 2>&1; then
                echo "FiveM process: RUNNING (PID: $PID)"
            else
                echo "FiveM process: NOT RUNNING (stale PID file)"
            fi
        else
            echo "FiveM process: NO PID FILE"
        fi
        
        echo ""
        echo "=== Recent Logs ==="
        if [ -f /mnt/fivem-server/fivem.log ]; then
            tail -10 /mnt/fivem-server/fivem.log
        else
            echo "No log file found"
        fi
EOF
}

# Start server
start_server() {
    get_connection_info
    print_status "Starting FiveM server..."
    ssh "$ADMIN_USER@$VM_IP" "sudo systemctl start fivem"
    print_status "Server started. Checking status..."
    ssh "$ADMIN_USER@$VM_IP" "sudo systemctl status fivem"
}

# Stop server
stop_server() {
    get_connection_info
    print_status "Stopping FiveM server..."
    ssh "$ADMIN_USER@$VM_IP" "sudo systemctl stop fivem"
    print_status "Server stopped."
}

# Restart server
restart_server() {
    get_connection_info
    print_status "Restarting FiveM server..."
    ssh "$ADMIN_USER@$VM_IP" "sudo systemctl restart fivem"
    print_status "Server restarted. Checking status..."
    ssh "$ADMIN_USER@$VM_IP" "sudo systemctl status fivem"
}

# View logs
view_logs() {
    get_connection_info
    print_status "Viewing FiveM server logs (press Ctrl+C to exit)..."
    ssh "$ADMIN_USER@$VM_IP" "tail -f /mnt/fivem-server/fivem.log"
}

# Check resource usage
check_resources() {
    get_connection_info
    print_status "Checking system resources..."
    ssh "$ADMIN_USER@$VM_IP" << 'EOF'
        echo "=== CPU and Memory Usage ==="
        top -bn1 | head -10
        echo ""
        echo "=== Disk Usage ==="
        df -h
        echo ""
        echo "=== FiveM Process ==="
        if [ -f /mnt/fivem-server/fivem.pid ]; then
            PID=$(cat /mnt/fivem-server/fivem.pid)
            ps aux | grep -E "(FXServer|$PID)" | grep -v grep
        else
            echo "No FiveM PID file found"
        fi
        echo ""
        echo "=== Network Connections ==="
        netstat -tulpn | grep :30120 || echo "FiveM port (30120) not listening"
EOF
}

# Update FiveM
update_fivem() {
    get_connection_info
    print_warning "This will stop the server, download the latest FiveM build, and restart."
    read -p "Continue? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Update cancelled."
        return
    fi
    
    print_status "Updating FiveM server..."
    ssh "$ADMIN_USER@$VM_IP" << 'EOF'
        # Stop the server
        sudo systemctl stop fivem
        
        # Backup current installation
        sudo cp -r /opt/fivem /opt/fivem.backup.$(date +%Y%m%d_%H%M%S)
        
        # Download latest FiveM
        cd /opt/fivem
        wget -O fx.tar.xz "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/16501-39ee6b6a1ddc38e57d12e5bf4766a7e3cc5830b8/fx.tar.xz"
        
        # Extract new version
        tar -xf fx.tar.xz
        rm fx.tar.xz
        
        # Fix permissions
        chown -R azureuser:azureuser /opt/fivem
        
        # Start the server
        sudo systemctl start fivem
        
        echo "FiveM updated successfully!"
EOF
    
    print_status "FiveM update completed. Checking status..."
    check_status
}

# Backup server data
backup_data() {
    get_connection_info
    print_status "Creating backup of server data..."
    BACKUP_NAME="fivem-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    ssh "$ADMIN_USER@$VM_IP" << EOF
        cd /mnt
        sudo tar -czf /home/$ADMIN_USER/$BACKUP_NAME fivem-server/ fivem-resources/
        echo "Backup created: /home/$ADMIN_USER/$BACKUP_NAME"
        ls -lh /home/$ADMIN_USER/$BACKUP_NAME
EOF
    
    print_status "Backup completed: $BACKUP_NAME"
    print_info "You can download it with: scp $ADMIN_USER@$VM_IP:~/$BACKUP_NAME ."
}

# Show help
show_help() {
    echo "FiveM Server Management Script"
    echo "=============================="
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  ssh         - SSH to the FiveM server VM"
    echo "  status      - Check FiveM server status"
    echo "  start       - Start FiveM server"
    echo "  stop        - Stop FiveM server"
    echo "  restart     - Restart FiveM server"
    echo "  logs        - View live server logs"
    echo "  resources   - Check system resource usage"
    echo "  update      - Update FiveM to latest version"
    echo "  backup      - Create backup of server data"
    echo "  info        - Show connection information"
    echo "  help        - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 ssh                # Connect to server"
    echo "  $0 start              # Start FiveM server"
    echo "  $0 logs               # Watch server logs"
    echo "  $0 backup             # Create data backup"
}

# Show connection info
show_info() {
    get_connection_info
    terraform output
    echo
    print_info "FiveM Server Connection: $VM_IP:30120"
    print_info "SSH Connection: ssh $ADMIN_USER@$VM_IP"
}

# Main function
main() {
    case "${1:-help}" in
        ssh)
            ssh_to_vm
            ;;
        status)
            check_status
            ;;
        start)
            start_server
            ;;
        stop)
            stop_server
            ;;
        restart)
            restart_server
            ;;
        logs)
            view_logs
            ;;
        resources)
            check_resources
            ;;
        update)
            update_fivem
            ;;
        backup)
            backup_data
            ;;
        info)
            show_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
