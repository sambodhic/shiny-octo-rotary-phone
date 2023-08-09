resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name_prefix
  location = var.resource_group_location
}

resource "random_string" "azurerm_storage_account_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_string" "azurerm_batch_account_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  name                     = "storage${random_string.azurerm_storage_account_name.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = element(split("_", var.storage_account_type), 0)
  account_replication_type = element(split("_", var.storage_account_type), 1)
}

resource "azurerm_batch_account" "batch" {
  name                                = "batch${random_string.azurerm_batch_account_name.result}"
  resource_group_name                 = azurerm_resource_group.rg.name
  location                            = azurerm_resource_group.rg.location
  storage_account_id                  = azurerm_storage_account.storage.id
  storage_account_authentication_mode = "StorageKeys"
}

resource "azurerm_monitor_workspace" "mamw" {
  name                = "kai-mamw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "westus2"
  tags = {
    key = "value"
  }
}

resource "azurerm_monitor_action_group" "main" {
  name                = "kai-actiongroup"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "p0action"

  webhook_receiver {
    name        = "callmyapi"
    service_uri = "http://example.com/alert"
  }
}

resource "azurerm_monitor_activity_log_alert" "main" {
  name                = "kai-activitylogalert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_resource_group.rg.id]
  description         = "This alert will monitor a specific storage account updates."

  criteria {
    resource_id    = azurerm_storage_account.storage.id
    operation_name = "Microsoft.Storage/storageAccounts/write"
    category       = "Recommendation"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id

    webhook_properties = {
      from = "terraform"
    }
  }
}