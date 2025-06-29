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

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (RSA supported)"
  type        = string
  validation {
    condition     = can(regex("^(ssh-rsa) ", var.ssh_public_key))
    error_message = "SSH public key must be RSA format (starting with 'ssh-rsa')."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
      "Standard_E2s_v3", "Standard_E4s_v3", "Standard_E8s_v3"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size."
  }
}

variable "os_disk_type" {
  description = "OS disk storage type"
  type        = string
  default     = "Standard_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "OS disk type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 2048
    error_message = "OS disk size must be between 30 and 2048 GB."
  }
}

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
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

variable "fivem_storage_quota_gb" {
  description = "FiveM server file share quota in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.fivem_storage_quota_gb >= 1 && var.fivem_storage_quota_gb <= 102400
    error_message = "FiveM storage quota must be between 1 and 102400 GB."
  }
}

variable "fivem_resources_quota_gb" {
  description = "FiveM resources file share quota in GB"
  type        = number
  default     = 30
  validation {
    condition     = var.fivem_resources_quota_gb >= 1 && var.fivem_resources_quota_gb <= 102400
    error_message = "FiveM resources quota must be between 1 and 102400 GB."
  }
}

variable "fivem_cache_quota_gb" {
  description = "FiveM cache file share quota in GB"
  type        = number
  default     = 10
  validation {
    condition     = var.fivem_cache_quota_gb >= 1 && var.fivem_cache_quota_gb <= 102400
    error_message = "FiveM cache quota must be between 1 and 102400 GB."
  }
}

variable "fivem_download_url" {
  description = "FiveM server download URL"
  type        = string
  default     = "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/16501-39ee6b6a1ddc38e57d12e5bf4766a7e3cc5830b8/fx.tar.xz"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "FiveM"
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "gaming-server"
  }
}

variable "enable_auto_shutdown" {
  description = "Enable automatic VM shutdown to reduce costs"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time for automatic VM shutdown (24-hour format, e.g., '0200' for 2 AM)"
  type        = string
  default     = "0200"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for automatic shutdown"
  type        = string
  default     = "UTC"
}
