# Generate random suffix for globally unique resource names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Generate random password for PostgreSQL if not provided
resource "random_password" "postgres_password" {
  count   = var.postgres_admin_password == null ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}${var.environment}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}-${var.environment}-vault-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  tags = var.tags
}

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = var.postgres_admin_password != null ? var.postgres_admin_password : random_password.postgres_password[0].result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

# Store Container Registry credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.main.admin_username
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.main.admin_password
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-postgres-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.postgres_version
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password != null ? var.postgres_admin_password : random_password.postgres_password[0].result
  backup_retention_days  = 7
  sku_name               = var.postgres_sku_name
  storage_mb             = var.postgres_storage_mb

  tags = var.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "${var.project_name}_${var.environment}_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-${var.environment}-env-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = var.tags
}

# Container App
resource "azurerm_container_app" "main" {
  name                         = "${var.project_name}-${var.environment}-server-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.container_app_min_replicas
    max_replicas = var.container_app_max_replicas

    container {
      name   = "${var.project_name}-app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = var.container_app_cpu
      memory = var.container_app_memory

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgres_admin_username}:${var.postgres_admin_password != null ? var.postgres_admin_password : random_password.postgres_password[0].result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_NAME"
        value = var.project_name
      }

      env {
        name  = "STORAGE_ACCOUNT_NAME"
        value = azurerm_storage_account.main.name
      }

      env {
        name  = "STORAGE_CONNECTION_STRING"
        value = azurerm_storage_account.main.primary_connection_string
      }

      env {
        name  = "STORAGE_BLOB_ENDPOINT"
        value = azurerm_storage_account.main.primary_blob_endpoint
      }
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Store database connection string in Key Vault
resource "azurerm_key_vault_secret" "database_url" {
  name         = "database-url"
  value        = "postgresql://${var.postgres_admin_username}:${var.postgres_admin_password != null ? var.postgres_admin_password : random_password.postgres_password[0].result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}${var.environment}storage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"
  access_tier              = var.storage_account_access_tier
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = var.storage_allow_public_access
  shared_access_key_enabled       = true
  public_network_access_enabled   = true

  # Blob properties
  blob_properties {
    versioning_enabled       = var.storage_blob_versioning_enabled
    change_feed_enabled      = var.storage_blob_change_feed_enabled
    change_feed_retention_in_days = var.storage_blob_change_feed_retention_days
    last_access_time_enabled = var.storage_blob_last_access_time_enabled

    # Container delete retention policy
    container_delete_retention_policy {
      days = var.storage_blob_container_delete_retention_days
    }

    # Blob delete retention policy
    delete_retention_policy {
      days = var.storage_blob_delete_retention_days
    }
  }

  # Queue properties
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }

    minute_metrics {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 10
    }

    hour_metrics {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 10
    }
  }

  tags = var.tags
}

# Storage Containers
resource "azurerm_storage_container" "app_data" {
  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = var.storage_container_access_type
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = var.storage_container_access_type
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Storage File Shares
resource "azurerm_storage_share" "app_config" {
  name                 = "app-config"
  storage_account_name = azurerm_storage_account.main.name
  quota                = var.storage_file_share_quota_gb
  enabled_protocol     = "SMB"

  acl {
    id = "app-config-acl"

    access_policy {
      permissions = "rwdl"
      start       = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
      expiry      = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
    }
  }
}

resource "azurerm_storage_share" "shared_data" {
  name                 = "shared-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = var.storage_file_share_quota_gb
  enabled_protocol     = "SMB"

  acl {
    id = "shared-data-acl"

    access_policy {
      permissions = "rwdl"
      start       = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
      expiry      = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
    }
  }
}

# Storage Account Tables
resource "azurerm_storage_table" "app_sessions" {
  name                 = "appsessions"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_table" "app_logs" {
  name                 = "applogs"
  storage_account_name = azurerm_storage_account.main.name
}

# Storage Queue
resource "azurerm_storage_queue" "processing_queue" {
  name                 = "processing-queue"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "notification_queue" {
  name                 = "notification-queue"
  storage_account_name = azurerm_storage_account.main.name
}

# Store Storage Account credentials in Key Vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.main.name
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.main.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "storage_blob_endpoint" {
  name         = "storage-blob-endpoint"
  value        = azurerm_storage_account.main.primary_blob_endpoint
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault.main]
}
