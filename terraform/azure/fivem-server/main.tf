# Generate random suffix for globally unique resource names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "fivem" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "fivem" {
  name                = "${var.project_name}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "fivem" {
  name                 = "${var.project_name}-${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.fivem.name
  virtual_network_name = azurerm_virtual_network.fivem.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group and rules
resource "azurerm_network_security_group" "fivem" {
  name                = "${var.project_name}-${var.environment}-nsg"
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMInbound30120UDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "30120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMInbound30120TCP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMOutbound30120UDP"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "30120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMOutbound30120TCP"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMInbound40120TCP"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "40120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FiveMOutbound40120TCP"
    priority                   = 1007
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "40120"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "fivem" {
  subnet_id                 = azurerm_subnet.fivem.id
  network_security_group_id = azurerm_network_security_group.fivem.id
}

# Public IP
resource "azurerm_public_ip" "fivem" {
  name                = "${var.project_name}-${var.environment}-pip"
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface
resource "azurerm_network_interface" "fivem" {
  name                = "${var.project_name}-${var.environment}-nic"
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.fivem.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fivem.id
  }

  tags = var.tags
}

# Storage Account for FiveM data
resource "azurerm_storage_account" "fivem" {
  name                     = "fivem${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.fivem.name
  location                 = azurerm_resource_group.fivem.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = true

  tags = var.tags
}

# Storage File Shares for FiveM data
resource "azurerm_storage_share" "fivem_server" {
  name                 = "fivem-server"
  storage_account_name = azurerm_storage_account.fivem.name
  quota                = var.fivem_storage_quota_gb
  enabled_protocol     = "SMB"

  acl {
    id = "fivem-server-acl"

    access_policy {
      permissions = "rwdl"
      start       = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
      expiry      = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
    }
  }
}

resource "azurerm_storage_share" "fivem_resources" {
  name                 = "fivem-resources"
  storage_account_name = azurerm_storage_account.fivem.name
  quota                = var.fivem_resources_quota_gb
  enabled_protocol     = "SMB"

  acl {
    id = "fivem-resources-acl"

    access_policy {
      permissions = "rwdl"
      start       = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
      expiry      = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
    }
  }
}

resource "azurerm_storage_share" "fivem_cache" {
  name                 = "fivem-cache"
  storage_account_name = azurerm_storage_account.fivem.name
  quota                = var.fivem_cache_quota_gb
  enabled_protocol     = "SMB"

  acl {
    id = "fivem-cache-acl"

    access_policy {
      permissions = "rwdl"
      start       = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
      expiry      = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
    }
  }
}

# User-assigned managed identity for VM
resource "azurerm_user_assigned_identity" "fivem_vm" {
  name                = "${var.project_name}-${var.environment}-vm-identity"
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name
  tags                = var.tags
}

# Role assignment for storage access
resource "azurerm_role_assignment" "fivem_storage_contributor" {
  scope                = azurerm_storage_account.fivem.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.fivem_vm.principal_id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "fivem" {
  name                = "${var.project_name}-${var.environment}-vm"
  location            = azurerm_resource_group.fivem.location
  resource_group_name = azurerm_resource_group.fivem.name
  size                = var.vm_size
  admin_username      = var.admin_username

  # Disable password authentication
  disable_password_authentication = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.fivem_vm.id]
  }

  network_interface_ids = [
    azurerm_network_interface.fivem.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.yaml", {
    storage_account_name = azurerm_storage_account.fivem.name
    storage_account_key  = azurerm_storage_account.fivem.primary_access_key
    admin_username       = var.admin_username
    fivem_download_url   = var.fivem_download_url
  }))

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.fivem_storage_contributor
  ]
}

# Auto-shutdown schedule to reduce costs
resource "azurerm_dev_test_global_vm_shutdown_schedule" "fivem_vm" {
  virtual_machine_id = azurerm_linux_virtual_machine.fivem.id
  location           = azurerm_resource_group.fivem.location
  enabled            = var.enable_auto_shutdown

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled         = false
  }

  tags = var.tags
}
