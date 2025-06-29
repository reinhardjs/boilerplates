output "vm_public_ip" {
  description = "Public IP address of the FiveM server VM"
  value       = azurerm_public_ip.fivem.ip_address
}

output "vm_fqdn" {
  description = "FQDN of the FiveM server VM"
  value       = azurerm_public_ip.fivem.fqdn
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.fivem.ip_address}"
}

output "fivem_server_endpoint" {
  description = "FiveM server connection endpoint"
  value       = "${azurerm_public_ip.fivem.ip_address}:30120"
}

output "fivem_admin_endpoint" {
  description = "FiveM server connection endpoint"
  value       = "${azurerm_public_ip.fivem.ip_address}:40120"
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.fivem.name
}

output "storage_account_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.fivem.primary_access_key
  sensitive   = true
}

output "file_shares" {
  description = "Created file shares for FiveM"
  value = {
    server    = azurerm_storage_share.fivem_server.name
    resources = azurerm_storage_share.fivem_resources.name
    cache     = azurerm_storage_share.fivem_cache.name
  }
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.fivem.name
}
