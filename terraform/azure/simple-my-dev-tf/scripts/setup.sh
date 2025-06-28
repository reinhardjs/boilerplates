#!/bin/bash

# Azure Infrastructure Setup Script
# This script automates the complete setup of Azure infrastructure using Terraform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it first."
        echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install it first."
        echo "Visit: https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed."
}

# Function to authenticate with Azure
azure_login() {
    print_status "Checking Azure authentication..."
    
    # Check if already logged in
    if az account show >/dev/null 2>&1; then
        print_success "Already authenticated with Azure."
        az account show --output table
    else
        print_status "Logging into Azure..."
        az login
    fi
    
    # List available subscriptions
    print_status "Available subscriptions:"
    az account list --output table
    
    # Ask user to confirm or set subscription
    echo ""
    read -p "Do you want to use the current subscription? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter the subscription ID to use: " SUBSCRIPTION_ID
        az account set --subscription "$SUBSCRIPTION_ID"
        print_success "Subscription set to: $SUBSCRIPTION_ID"
    fi
}

# Function to setup terraform configuration
setup_terraform_config() {
    print_status "Setting up Terraform configuration..."
    
    # Copy terraform.tfvars.example to terraform.tfvars if it doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "terraform.tfvars created from example. Please review and modify as needed."
        
        # Generate a random password for PostgreSQL
        POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
        sed -i "s/# postgres_admin_password = \"YourSecurePassword123!\"/postgres_admin_password = \"${POSTGRES_PASSWORD}Aa1!\"/" terraform.tfvars
        print_success "Generated random PostgreSQL password and updated terraform.tfvars"
    else
        print_success "terraform.tfvars already exists."
    fi
}

# Function to initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized successfully."
}

# Function to validate and plan
terraform_plan() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_success "Terraform configuration is valid."
    
    print_status "Creating Terraform execution plan..."
    terraform plan -out=tfplan
    print_success "Terraform plan created successfully."
}

# Function to apply Terraform
terraform_apply() {
    print_status "Applying Terraform configuration..."
    echo ""
    print_warning "This will create Azure resources. Review the plan above."
    read -p "Do you want to proceed with the deployment? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Infrastructure deployed successfully!"
        
        # Show outputs
        print_status "Deployment Summary:"
        terraform output -json | jq -r '.deployment_summary.value | to_entries[] | "\(.key): \(.value)"'
    else
        print_warning "Deployment cancelled by user."
        rm -f tfplan
        exit 0
    fi
}

# Function to setup git repository
setup_git() {
    print_status "Setting up Git repository..."
    
    if [ ! -d ".git" ]; then
        git init
        print_success "Git repository initialized."
    else
        print_success "Git repository already exists."
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << EOF
# Terraform files
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
.terraform/
.terraform.lock.hcl

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log

# Environment files
.env
.env.local
.env.*.local
EOF
        print_success "Created .gitignore file."
    fi
    
    # Add files to git
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        print_success "No changes to commit."
    else
        git commit -m "Initial Terraform Azure infrastructure setup - $(date)"
        print_success "Changes committed to Git."
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    print_success "=== DEPLOYMENT COMPLETE ==="
    echo ""
    print_status "Next steps:"
    echo "1. Review the deployed resources in Azure Portal"
    echo "2. Configure your application images in the Container Registry"
    echo "3. Update the Container App with your application configuration"
    echo "4. Set up your database schema in PostgreSQL"
    echo "5. Configure CI/CD pipelines for automated deployments"
    echo ""
    print_status "Useful commands:"
    echo "• View outputs: terraform output"
    echo "• Update infrastructure: terraform plan && terraform apply"
    echo "• Destroy infrastructure: terraform destroy"
    echo "• Connect to PostgreSQL: Check Key Vault for connection details"
    echo ""
    print_status "Resource URLs:"
    echo "• Container App: $(terraform output -raw container_app_url 2>/dev/null || echo 'Run terraform output container_app_url')"
    echo "• Key Vault: $(terraform output -raw key_vault_uri 2>/dev/null || echo 'Run terraform output key_vault_uri')"
    echo "• Container Registry: $(terraform output -raw container_registry_login_server 2>/dev/null || echo 'Run terraform output container_registry_login_server')"
}

# Main execution
main() {
    echo ""
    print_status "=== Azure Infrastructure Setup ==="
    echo ""
    
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    check_prerequisites
    azure_login
    setup_terraform_config
    terraform_init
    terraform_plan
    terraform_apply
    setup_git
    show_next_steps
    
    print_success "Setup completed successfully!"
}

# Run main function
main "$@"
