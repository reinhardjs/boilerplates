#!/bin/bash

# Cleanup Script for Azure Infrastructure
# This script safely destroys all created resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if authenticated
check_auth() {
    if ! az account show >/dev/null 2>&1; then
        print_error "Not authenticated with Azure. Please run 'az login' first."
        exit 1
    fi
    
    if [ ! -d ".terraform" ]; then
        print_error "Terraform not initialized. No infrastructure to destroy."
        exit 1
    fi
}

# Function to show current resources
show_resources() {
    print_status "Current infrastructure:"
    terraform state list 2>/dev/null || print_warning "No resources found in state."
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_status "Planning destruction of infrastructure..."
    
    # Create destroy plan
    terraform plan -destroy -out=destroy.tfplan
    
    echo ""
    print_warning "=== DANGER: This will destroy ALL resources shown above ==="
    print_warning "This action cannot be undone!"
    echo ""
    
    read -p "Are you sure you want to destroy all infrastructure? Type 'yes' to confirm: " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        print_status "Destroying infrastructure..."
        terraform apply destroy.tfplan
        print_success "All infrastructure has been destroyed."
        
        # Clean up plan file
        rm -f destroy.tfplan
        
        # Commit destruction if git repository exists
        if [ -d ".git" ]; then
            git add .
            if ! git diff --staged --quiet; then
                git commit -m "Infrastructure destroyed - $(date)"
                print_success "Destruction logged in Git."
            fi
        fi
    else
        print_warning "Destruction cancelled."
        rm -f destroy.tfplan
        exit 0
    fi
}

# Function to clean up local files
cleanup_local() {
    read -p "Do you want to clean up local Terraform files? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up local files..."
        rm -rf .terraform
        rm -f .terraform.lock.hcl
        rm -f *.tfplan
        rm -f terraform.tfstate*
        print_success "Local Terraform files cleaned up."
    fi
}

# Main execution
main() {
    cd "$(dirname "$0")/.."
    
    print_status "=== Infrastructure Cleanup ==="
    check_auth
    show_resources
    destroy_infrastructure
    cleanup_local
    
    print_success "Cleanup completed!"
    print_status "You can run './scripts/setup.sh' to recreate the infrastructure."
}

main "$@"
