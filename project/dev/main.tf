resource "azurerm_resource_group" "kai" {
  name     = "kai-resources"
  location = "westus3"
}

resource "azurerm_container_registry" "acr" {
  name                = "kaidev"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  sku                 = "Basic"
  admin_enabled       = true
}

module "azurerm_virtual_network" {
  source = "../modules/services/network"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
}

module "azurerm_application_gateway" {
  source = "../modules/services/gateway"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
  subnet_id               = module.azurerm_virtual_network.frontend.id
  public_ip_address_id    = module.azurerm_virtual_network.publicip.id

  backend_address_pool_name      = "${module.azurerm_virtual_network.name}-beap"
  frontend_port_name             = "${module.azurerm_virtual_network.name}-feport"
  frontend_ip_configuration_name = "${module.azurerm_virtual_network.name}-feip"
  http_setting_name              = "${module.azurerm_virtual_network.name}-be-htst"
  listener_name                  = "${module.azurerm_virtual_network.name}-httplstn"
  request_routing_rule_name      = "${module.azurerm_virtual_network.name}-rqrt"
  redirect_configuration_name    = "${module.azurerm_virtual_network.name}-rdrcfg"
}

module "azurerm_service_plan" {
  source = "../modules/services/appserver-cluster"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
}

module "azurerm_postgresql_server" {
  source = "../dev/data-stores/postgresql"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
}

module "azurerm_batch_application" {
  source = "../modules/services/batchstorage"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
}

module "azurerm_key_vault" {
  source = "../modules/services/keyvault"

  resource_group_name     = azurerm_resource_group.kai.name
  resource_group_location = azurerm_resource_group.kai.location
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "kaisa" {
  name                = "kai-sa-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_batch_application.kaisa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaiba" {
  name                = "kai-ba-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_batch_application.kaiba.id
    subresource_names              = ["batchAccount"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaikv" {
  name                = "kai-kv-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaidb" {
  name                = "kai-db-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_postgresql_server.kaidb.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaife" {
  name                = "kai-fe-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_service_plan.kaifrontend.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaibe" {
  name                = "kai-be-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = module.azurerm_virtual_network.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = module.azurerm_service_plan.kaibackend.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "kaiLaw"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "kai-appinsights" {
  name                = "kai-appinsights"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

resource "azurerm_monitor_workspace" "mamw" {
  name                = "kai-mamw"
  resource_group_name = azurerm_resource_group.kai.name
  location            = "westus2"
  tags = {
    key = "value"
  }
}
