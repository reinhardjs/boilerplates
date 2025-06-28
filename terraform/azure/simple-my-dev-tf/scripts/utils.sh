#!/bin/bash

# Utility script for managing secrets and credentials

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  secrets         - List all secrets in Key Vault"
    echo "  database        - Show database connection details"
    echo "  registry        - Show container registry credentials"
    echo "  urls            - Show all service URLs"
    echo "  logs            - Show recent container app logs"
    echo "  status          - Show status of all resources"
    echo "  help            - Show this help message"
}

# Function to get terraform output safely
get_terraform_output() {
    local output_name="$1"
    terraform output -raw "$output_name" 2>/dev/null || echo ""
}

# Function to list Key Vault secrets
list_secrets() {
    local kv_name=$(get_terraform_output "key_vault_name")
    if [ -z "$kv_name" ]; then
        print_error "Cannot get Key Vault name from Terraform output"
        return 1
    fi
    
    print_status "Key Vault Secrets in '$kv_name':"
    az keyvault secret list --vault-name "$kv_name" --output table
}

# Function to show database connection details
show_database_info() {
    local kv_name=$(get_terraform_output "key_vault_name")
    local postgres_fqdn=$(get_terraform_output "postgres_server_fqdn")
    local postgres_user=$(get_terraform_output "postgres_admin_username")
    local db_name=$(get_terraform_output "postgres_database_name")
    
    print_status "PostgreSQL Connection Details:"
    echo "Server: $postgres_fqdn"
    echo "Username: $postgres_user"
    echo "Database: $db_name"
    echo "Port: 5432"
    echo ""
    print_status "Connection string stored in Key Vault secret: 'database-url'"
    
    if [ -n "$kv_name" ]; then
        echo ""
        read -p "Do you want to view the connection string? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            az keyvault secret show --vault-name "$kv_name" --name "database-url" --query "value" -o tsv
        fi
    fi
}

# Function to show container registry credentials
show_registry_info() {
    local kv_name=$(get_terraform_output "key_vault_name")
    local acr_server=$(get_terraform_output "container_registry_login_server")
    
    print_status "Container Registry Details:"
    echo "Login Server: $acr_server"
    echo ""
    print_status "Credentials stored in Key Vault:"
    echo "Username secret: 'acr-username'"
    echo "Password secret: 'acr-password'"
    
    if [ -n "$kv_name" ]; then
        echo ""
        read -p "Do you want to view the credentials? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Username: $(az keyvault secret show --vault-name "$kv_name" --name "acr-username" --query "value" -o tsv)"
            echo "Password: $(az keyvault secret show --vault-name "$kv_name" --name "acr-password" --query "value" -o tsv)"
        fi
    fi
    
    echo ""
    print_status "To login to the registry:"
    echo "az acr login --name $(echo $acr_server | cut -d'.' -f1)"
}

# Function to show all service URLs
show_urls() {
    print_status "Service URLs:"
    echo "Container App: $(get_terraform_output "container_app_url")"
    echo "Key Vault: $(get_terraform_output "key_vault_uri")"
    echo "Container Registry: https://$(get_terraform_output "container_registry_login_server")"
    
    local rg_name=$(get_terraform_output "resource_group_name")
    if [ -n "$rg_name" ]; then
        echo "Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rg_name"
    fi
}

# Function to show container app logs
show_logs() {
    local app_name=$(get_terraform_output "container_app_name")
    local rg_name=$(get_terraform_output "resource_group_name")
    
    if [ -z "$app_name" ] || [ -z "$rg_name" ]; then
        print_error "Cannot get container app details from Terraform output"
        return 1
    fi
    
    print_status "Recent logs for Container App '$app_name':"
    az containerapp logs show --name "$app_name" --resource-group "$rg_name" --follow false --tail 50
}

# Function to show resource status
show_status() {
    local rg_name=$(get_terraform_output "resource_group_name")
    
    if [ -z "$rg_name" ]; then
        print_error "Cannot get resource group name from Terraform output"
        return 1
    fi
    
    print_status "Resource Status in '$rg_name':"
    az resource list --resource-group "$rg_name" --output table
}

# Main function
main() {
    cd "$(dirname "$0")/.."
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    case "$1" in
        "secrets")
            list_secrets
            ;;
        "database")
            show_database_info
            ;;
        "registry")
            show_registry_info
            ;;
        "urls")
            show_urls
            ;;
        "logs")
            show_logs
            ;;
        "status")
            show_status
            ;;
        "help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
