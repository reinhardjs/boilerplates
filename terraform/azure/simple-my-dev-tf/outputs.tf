output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the key vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "container_app_environment_name" {
  description = "Name of the container app environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_name" {
  description = "Name of the container app"
  value       = azurerm_container_app.main.name
}

output "container_app_url" {
  description = "URL of the container app"
  value       = "https://${azurerm_container_app.main.latest_revision_fqdn}"
}

output "log_analytics_workspace_name" {
  description = "Name of the log analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the log analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group         = azurerm_resource_group.main.name
    container_registry     = azurerm_container_registry.main.login_server
    key_vault             = azurerm_key_vault.main.vault_uri
    postgres_server       = azurerm_postgresql_flexible_server.main.fqdn
    container_app_url     = "https://${azurerm_container_app.main.latest_revision_fqdn}"
    log_analytics         = azurerm_log_analytics_workspace.main.name
    storage_account       = azurerm_storage_account.main.name
    storage_blob_endpoint = azurerm_storage_account.main.primary_blob_endpoint
  }
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_primary_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Primary connection string of the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_containers" {
  description = "List of storage containers"
  value = {
    app_data = azurerm_storage_container.app_data.name
    uploads  = azurerm_storage_container.uploads.name
    backups  = azurerm_storage_container.backups.name
    logs     = azurerm_storage_container.logs.name
  }
}

output "storage_file_shares" {
  description = "List of storage file shares"
  value = {
    app_config   = azurerm_storage_share.app_config.name
    shared_data  = azurerm_storage_share.shared_data.name
  }
}

output "storage_tables" {
  description = "List of storage tables"
  value = {
    app_sessions = azurerm_storage_table.app_sessions.name
    app_logs     = azurerm_storage_table.app_logs.name
  }
}

output "storage_queues" {
  description = "List of storage queues"
  value = {
    processing_queue   = azurerm_storage_queue.processing_queue.name
    notification_queue = azurerm_storage_queue.notification_queue.name
  }
}
