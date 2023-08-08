output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "gateway_frontend_ip" {
  value = "http://${azurerm_public_ip.pip.ip_address}"
}

output "azurerm_postgresql_flexible_server" {
  value = azurerm_postgresql_flexible_server.database.name
}

output "postgresql_flexible_server_database_name" {
  value = azurerm_postgresql_flexible_server_database.database.name
}

output "batch_name" {
  value = azurerm_batch_account.batch.name
}

output "storage_name" {
  value = azurerm_storage_account.storage.name
}

output "azurerm_key_vault_name" {
  value = azurerm_key_vault.vault.name
}
