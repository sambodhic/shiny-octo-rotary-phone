resource "azurerm_storage_account" "kaisa" {
  name                     = "kaisa"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_batch_account" "kaiba" {
  name                                = "kaiba"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  pool_allocation_mode                = "BatchService"
  storage_account_id                  = azurerm_storage_account.kaisa.id
  storage_account_authentication_mode = "StorageKeys"
}

resource "azurerm_batch_application" "kai" {
  name                = "kai-batch-application"
  resource_group_name        = var.resource_group_name
  account_name        = azurerm_batch_account.kaiba.name
}