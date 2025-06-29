#!/bin/bash

# FiveM Server Deployment Script
# This script helps deploy the FiveM server infrastructure

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

# Check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    print_status "Terraform is installed: $(terraform version | head -n1)"
}

# Check if Azure CLI is installed and logged in
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_status "Azure CLI is configured and logged in"
    az account show --query "{name:name, id:id}" -o table
}

# Check if terraform.tfvars exists
check_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found."
        print_info "Copying terraform.tfvars.example to terraform.tfvars"
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration before proceeding."
        print_info "At minimum, you need to set your SSH public key:"
        print_info "  ssh_public_key = \"ssh-rsa AAAAB3NzaC1yc2E...\""
        echo
        read -p "Do you want to edit terraform.tfvars now? (y/n): " edit_vars
        if [[ $edit_vars =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} terraform.tfvars
        else
            print_error "Please edit terraform.tfvars before running this script again."
            exit 1
        fi
    fi
    print_status "terraform.tfvars found"
}

# Validate SSH key in tfvars
validate_ssh_key() {
    if grep -q "your-public-key-here" terraform.tfvars; then
        print_error "Please update the SSH public key in terraform.tfvars"
        exit 1
    fi
    print_status "SSH public key appears to be configured"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
}

# Plan Terraform
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    echo
    print_info "Review the plan above. This will create:"
    print_info "  - Resource Group"
    print_info "  - Virtual Network and Subnet"
    print_info "  - Network Security Group (SSH + FiveM ports)"
    print_info "  - Public IP"
    print_info "  - Storage Account with File Shares"
    print_info "  - Virtual Machine with FiveM auto-setup"
    echo
    
    read -p "Do you want to apply this plan? (y/n): " apply_plan
    if [[ ! $apply_plan =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
}

# Apply Terraform
apply_terraform() {
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        print_status "Deployment completed successfully!"
        echo
        print_info "Getting connection information..."
        terraform output
        echo
        print_info "Your FiveM server is being set up. This may take 5-10 minutes."
        print_info "You can monitor the setup progress by SSHing to the VM and checking:"
        print_info "  sudo cloud-init status"
        print_info "  sudo journalctl -u cloud-final"
        echo
        print_info "Next steps:"
        print_info "1. SSH to your VM using the connection command above"
        print_info "2. Run ./start-fivem.sh to start the server"
        print_info "3. Connect via FiveM client to: <vm-ip>:30120"
    else
        print_error "Deployment failed. Check the error messages above."
        exit 1
    fi
}

# Main function
main() {
    print_status "FiveM Server Deployment Script"
    echo "========================================"
    
    check_terraform
    check_azure_cli
    check_tfvars
    validate_ssh_key
    init_terraform
    plan_terraform
    apply_terraform
}

# Run main function
main
