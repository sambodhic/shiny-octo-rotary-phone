resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "kai-appinsights" {
  name                = "${var.resource_group_name}-appinsights"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

resource "azurerm_monitor_workspace" "mamw" {
  name                = "${var.resource_group_name}-mamw"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags = {
    key = "value"
  }
}
