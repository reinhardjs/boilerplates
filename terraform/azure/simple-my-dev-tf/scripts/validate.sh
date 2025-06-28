#!/bin/bash

# Validation Script for Azure Infrastructure
# This script validates the deployed infrastructure

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
}

# Function to validate resource group
validate_resource_group() {
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    if [ -z "$rg_name" ]; then
        print_error "Cannot get resource group name from Terraform output"
        return 1
    fi
    
    print_status "Validating Resource Group: $rg_name"
    if az group show --name "$rg_name" >/dev/null 2>&1; then
        print_success "Resource Group exists and is accessible"
    else
        print_error "Resource Group not found or not accessible"
        return 1
    fi
}

# Function to validate container registry
validate_container_registry() {
    local acr_name=$(terraform output -raw container_registry_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating Container Registry: $acr_name"
    if az acr show --name "$acr_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "Container Registry exists and is accessible"
        
        # Check if admin is enabled
        local admin_enabled=$(az acr show --name "$acr_name" --resource-group "$rg_name" --query "adminUserEnabled" -o tsv)
        if [ "$admin_enabled" = "true" ]; then
            print_success "Container Registry admin user is enabled"
        else
            print_warning "Container Registry admin user is disabled"
        fi
    else
        print_error "Container Registry not found or not accessible"
        return 1
    fi
}

# Function to validate key vault
validate_key_vault() {
    local kv_name=$(terraform output -raw key_vault_name 2>/dev/null)
    
    print_status "Validating Key Vault: $kv_name"
    if az keyvault show --name "$kv_name" >/dev/null 2>&1; then
        print_success "Key Vault exists and is accessible"
        
        # Check secrets
        print_status "Checking Key Vault secrets..."
        local secrets=("postgres-admin-password" "acr-username" "acr-password" "database-url")
        for secret in "${secrets[@]}"; do
            if az keyvault secret show --vault-name "$kv_name" --name "$secret" >/dev/null 2>&1; then
                print_success "Secret '$secret' exists"
            else
                print_warning "Secret '$secret' not found"
            fi
        done
    else
        print_error "Key Vault not found or not accessible"
        return 1
    fi
}

# Function to validate PostgreSQL server
validate_postgres() {
    local postgres_name=$(terraform output -raw postgres_server_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating PostgreSQL Server: $postgres_name"
    if az postgres flexible-server show --name "$postgres_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "PostgreSQL Server exists and is accessible"
        
        # Check server state
        local state=$(az postgres flexible-server show --name "$postgres_name" --resource-group "$rg_name" --query "state" -o tsv)
        if [ "$state" = "Ready" ]; then
            print_success "PostgreSQL Server is ready"
        else
            print_warning "PostgreSQL Server state: $state"
        fi
        
        # List databases
        print_status "Checking PostgreSQL databases..."
        az postgres flexible-server db list --server-name "$postgres_name" --resource-group "$rg_name" --output table
    else
        print_error "PostgreSQL Server not found or not accessible"
        return 1
    fi
}

# Function to validate container app environment
validate_container_app_env() {
    local env_name=$(terraform output -raw container_app_environment_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating Container App Environment: $env_name"
    if az containerapp env show --name "$env_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "Container App Environment exists and is accessible"
    else
        print_error "Container App Environment not found or not accessible"
        return 1
    fi
}

# Function to validate container app
validate_container_app() {
    local app_name=$(terraform output -raw container_app_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating Container App: $app_name"
    if az containerapp show --name "$app_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "Container App exists and is accessible"
        
        # Check app status
        local provisioning_state=$(az containerapp show --name "$app_name" --resource-group "$rg_name" --query "properties.provisioningState" -o tsv)
        print_status "Container App provisioning state: $provisioning_state"
        
        # Get app URL
        local app_url=$(terraform output -raw container_app_url 2>/dev/null)
        print_status "Container App URL: $app_url"
        
        # Test connectivity (optional)
        print_status "Testing Container App connectivity..."
        if curl -s --max-time 10 "$app_url" >/dev/null; then
            print_success "Container App is responding to HTTP requests"
        else
            print_warning "Container App is not responding (this might be normal if no app is deployed)"
        fi
    else
        print_error "Container App not found or not accessible"
        return 1
    fi
}

# Function to validate log analytics workspace
validate_log_analytics() {
    local workspace_name=$(terraform output -raw log_analytics_workspace_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating Log Analytics Workspace: $workspace_name"
    if az monitor log-analytics workspace show --workspace-name "$workspace_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "Log Analytics Workspace exists and is accessible"
    else
        print_error "Log Analytics Workspace not found or not accessible"
        return 1
    fi
}

# Function to validate storage account
validate_storage_account() {
    local storage_name=$(terraform output -raw storage_account_name 2>/dev/null)
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_status "Validating Storage Account: $storage_name"
    if az storage account show --name "$storage_name" --resource-group "$rg_name" >/dev/null 2>&1; then
        print_success "Storage Account exists and is accessible"
        
        # Check storage containers
        print_status "Checking Storage Containers..."
        local containers=$(terraform output -json storage_containers 2>/dev/null | jq -r 'to_entries[] | .value')
        for container in $containers; do
            if az storage container show --name "$container" --account-name "$storage_name" >/dev/null 2>&1; then
                print_success "Container '$container' exists"
            else
                print_warning "Container '$container' not found"
            fi
        done
        
        # Check file shares
        print_status "Checking File Shares..."
        local shares=$(terraform output -json storage_file_shares 2>/dev/null | jq -r 'to_entries[] | .value')
        for share in $shares; do
            if az storage share show --name "$share" --account-name "$storage_name" >/dev/null 2>&1; then
                print_success "File share '$share' exists"
            else
                print_warning "File share '$share' not found"
            fi
        done
        
        # Check tables
        print_status "Checking Storage Tables..."
        local tables=$(terraform output -json storage_tables 2>/dev/null | jq -r 'to_entries[] | .value')
        for table in $tables; do
            if az storage table exists --name "$table" --account-name "$storage_name" >/dev/null 2>&1; then
                print_success "Table '$table' exists"
            else
                print_warning "Table '$table' not found"
            fi
        done
        
        # Check queues
        print_status "Checking Storage Queues..."
        local queues=$(terraform output -json storage_queues 2>/dev/null | jq -r 'to_entries[] | .value')
        for queue in $queues; do
            if az storage queue exists --name "$queue" --account-name "$storage_name" >/dev/null 2>&1; then
                print_success "Queue '$queue' exists"
            else
                print_warning "Queue '$queue' not found"
            fi
        done
        
        # Check storage account keys are in Key Vault
        print_status "Checking storage secrets in Key Vault..."
        local vault_name=$(terraform output -raw key_vault_name 2>/dev/null)
        if az keyvault secret show --vault-name "$vault_name" --name "storage-account-name" >/dev/null 2>&1; then
            print_success "Storage account name stored in Key Vault"
        else
            print_warning "Storage account name not found in Key Vault"
        fi
        
        if az keyvault secret show --vault-name "$vault_name" --name "storage-account-key" >/dev/null 2>&1; then
            print_success "Storage account key stored in Key Vault"
        else
            print_warning "Storage account key not found in Key Vault"
        fi
        
    else
        print_error "Storage Account not found or not accessible"
        return 1
    fi
}

# Function to show resource summary
show_resource_summary() {
    print_status "=== Resource Summary ==="
    echo ""
    terraform output deployment_summary
    echo ""
}

# Function to show costs (if available)
show_costs() {
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    print_status "=== Cost Information ==="
    print_status "Use the following command to check current costs:"
    echo "az consumption usage list --start-date $(date -d '1 month ago' +%Y-%m-%d) --end-date $(date +%Y-%m-%d) --output table"
}

# Main validation function
main() {
    cd "$(dirname "$0")/.."
    
    print_status "=== Infrastructure Validation ==="
    echo ""
    
    check_auth
    
    local validation_passed=true
    
    validate_resource_group || validation_passed=false
    validate_container_registry || validation_passed=false
    validate_key_vault || validation_passed=false
    validate_postgres || validation_passed=false
    validate_container_app_env || validation_passed=false
    validate_container_app || validation_passed=false
    validate_log_analytics || validation_passed=false
    validate_storage_account || validation_passed=false
    
    echo ""
    if [ "$validation_passed" = true ]; then
        print_success "=== All validations passed! ==="
        show_resource_summary
        show_costs
    else
        print_error "=== Some validations failed ==="
        print_status "Please check the errors above and run 'terraform plan' and 'terraform apply' if needed."
    fi
}

main "$@"
