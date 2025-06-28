#!/bin/bash

# Deployment Script for Azure Infrastructure
# This script handles updates and redeployments

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
        print_error "Terraform not initialized. Please run 'terraform init' first."
        exit 1
    fi
}

# Function to deploy/update infrastructure
deploy() {
    print_status "Deploying infrastructure updates..."
    
    # Format Terraform files
    terraform fmt
    
    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate
    
    # Create plan
    print_status "Creating deployment plan..."
    terraform plan -out=tfplan
    
    # Show plan summary
    echo ""
    print_warning "Review the changes above carefully."
    read -p "Do you want to apply these changes? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Deployment completed successfully!"
        
        # Commit changes if git repository exists
        if [ -d ".git" ]; then
            git add .
            if ! git diff --staged --quiet; then
                git commit -m "Infrastructure update - $(date)"
                print_success "Changes committed to Git."
            fi
        fi
        
        # Show outputs
        print_status "Updated deployment summary:"
        terraform output deployment_summary
    else
        print_warning "Deployment cancelled."
        rm -f tfplan
    fi
}

# Main execution
main() {
    cd "$(dirname "$0")/.."
    
    print_status "=== Infrastructure Deployment ==="
    check_auth
    deploy
}

main "$@"
