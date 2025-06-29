#!/bin/bash

# FiveM Server Cleanup Script
# This script helps destroy the FiveM server infrastructure

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

# Main function
main() {
    print_warning "FiveM Server Cleanup Script"
    echo "==========================================="
    echo
    print_warning "This will PERMANENTLY DELETE all resources including:"
    print_warning "  - Virtual Machine"
    print_warning "  - Storage Account and ALL DATA"
    print_warning "  - Public IP"
    print_warning "  - Network resources"
    print_warning "  - Resource Group"
    echo
    print_error "THIS ACTION CANNOT BE UNDONE!"
    echo
    
    read -p "Are you absolutely sure you want to destroy everything? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
    
    echo
    read -p "Type 'DESTROY' to confirm: " destroy_confirm
    if [[ $destroy_confirm != "DESTROY" ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
    
    print_status "Starting cleanup process..."
    
    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        print_error "No terraform.tfstate found. Nothing to destroy."
        exit 1
    fi
    
    # Show what will be destroyed
    print_status "Planning destruction..."
    terraform plan -destroy
    
    echo
    read -p "Proceed with destruction? (yes/no): " final_confirm
    if [[ $final_confirm != "yes" ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
    
    # Destroy resources
    print_status "Destroying resources..."
    terraform destroy -auto-approve
    
    if [ $? -eq 0 ]; then
        print_status "All resources have been successfully destroyed."
        
        # Clean up local files
        print_status "Cleaning up local files..."
        rm -f terraform.tfstate*
        rm -f tfplan
        rm -rf .terraform/
        
        print_status "Cleanup completed successfully!"
    else
        print_error "Destruction failed. Some resources may still exist."
        print_info "You may need to clean up manually in the Azure portal."
        exit 1
    fi
}

# Run main function
main
