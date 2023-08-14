resource "random_string" "azurerm_random_name" {
  length  = 7
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_storage_account" "kaisa" {
  name                     = "${var.resource_group_name}sa${random_string.azurerm_random_name.result}"
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_batch_account" "kaiba" {
  name                                = "${var.resource_group_name}ba${random_string.azurerm_random_name.result}"
  location                            = var.resource_group_location
  resource_group_name                 = var.resource_group_name
  pool_allocation_mode                = "BatchService"
  storage_account_id                  = azurerm_storage_account.kaisa.id
  storage_account_authentication_mode = "StorageKeys"
}

resource "azurerm_batch_application" "kai" {
  name                = "${var.resource_group_name}-batch-application"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_batch_account.kaiba.name
}