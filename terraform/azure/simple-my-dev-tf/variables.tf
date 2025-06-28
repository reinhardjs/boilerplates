variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West US 2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "my"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "adminuser"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "container_app_cpu" {
  description = "CPU allocation for container app"
  type        = string
  default     = "0.25"
}

variable "container_app_memory" {
  description = "Memory allocation for container app"
  type        = string
  default     = "0.5Gi"
}

variable "container_app_min_replicas" {
  description = "Minimum number of container app replicas"
  type        = number
  default     = 1
}

variable "container_app_max_replicas" {
  description = "Maximum number of container app replicas"
  type        = number
  default     = 3
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "my"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Storage Account Variables
variable "storage_account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be either Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "storage_account_access_tier" {
  description = "Storage account access tier for blob storage"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.storage_account_access_tier)
    error_message = "Storage account access tier must be either Hot or Cool."
  }
}

variable "storage_allow_public_access" {
  description = "Allow public access to storage account containers"
  type        = bool
  default     = false
}

variable "storage_blob_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "storage_blob_change_feed_enabled" {
  description = "Enable blob change feed"
  type        = bool
  default     = true
}

variable "storage_blob_change_feed_retention_days" {
  description = "Blob change feed retention in days"
  type        = number
  default     = 30
  validation {
    condition     = var.storage_blob_change_feed_retention_days >= 1 && var.storage_blob_change_feed_retention_days <= 146000
    error_message = "Blob change feed retention days must be between 1 and 146000."
  }
}

variable "storage_blob_last_access_time_enabled" {
  description = "Enable blob last access time tracking"
  type        = bool
  default     = true
}

variable "storage_blob_container_delete_retention_days" {
  description = "Container delete retention policy in days"
  type        = number
  default     = 7
  validation {
    condition     = var.storage_blob_container_delete_retention_days >= 1 && var.storage_blob_container_delete_retention_days <= 365
    error_message = "Container delete retention days must be between 1 and 365."
  }
}

variable "storage_blob_delete_retention_days" {
  description = "Blob delete retention policy in days"
  type        = number
  default     = 30
  validation {
    condition     = var.storage_blob_delete_retention_days >= 1 && var.storage_blob_delete_retention_days <= 365
    error_message = "Blob delete retention days must be between 1 and 365."
  }
}

variable "storage_container_access_type" {
  description = "Default access type for storage containers"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["private", "blob", "container"], var.storage_container_access_type)
    error_message = "Container access type must be one of: private, blob, container."
  }
}

variable "storage_file_share_quota_gb" {
  description = "File share quota in GB"
  type        = number
  default     = 100
  validation {
    condition     = var.storage_file_share_quota_gb >= 1 && var.storage_file_share_quota_gb <= 102400
    error_message = "File share quota must be between 1 and 102400 GB."
  }
}
