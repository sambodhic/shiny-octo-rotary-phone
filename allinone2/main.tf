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

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy
resource "azurerm_web_application_firewall_policy" "kai" {
  name                = "kai-wafpolicy"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }

    action = "Block"
  }

  custom_rules {
    name      = "Rule2"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24"]
    }

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }
}

resource "azurerm_virtual_network" "kai" {
  name                = "kai-network"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.kai.name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.kai.name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.1.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "kaiDatabaseSubnet"
  resource_group_name  = azurerm_resource_group.kai.name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_public_ip" "kai" {
  name                = "kai-pip"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.kai.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.kai.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.kai.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.kai.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.kai.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.kai.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.kai.name}-rdrcfg"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway.html
resource "azurerm_application_gateway" "network" {
  name                = "kai-appgateway"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.kai.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.kai.id
}

resource "azurerm_service_plan" "kai" {
  name                = "kai"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_resource_group.kai.location
  os_type             = "Linux"
  sku_name            = "S1"
  worker_count        = 3
}

resource "azurerm_linux_web_app" "kaifrontend" {
  name                = "kaifrontend"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_service_plan.kai.location
  service_plan_id     = azurerm_service_plan.kai.id

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  site_config {
    application_stack {
      # docker_image_name   = "kaidev.azurecr.io/app:latest"
      docker_image_name   = "nginx:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }
}

resource "azurerm_linux_web_app" "kaibackend" {
  name                = "kaibackend"
  resource_group_name = azurerm_resource_group.kai.name
  location            = azurerm_service_plan.kai.location
  service_plan_id     = azurerm_service_plan.kai.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
}

resource "random_password" "pass" {
  length = 20
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_server.html
resource "azurerm_postgresql_server" "kai" {
  name                = "postgresql-server-kai"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name

  sku_name = "GP_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = random_password.pass.result
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "kai" {
  name                = "kaidb"
  resource_group_name = azurerm_resource_group.kai.name
  server_name         = azurerm_postgresql_server.kai.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_storage_account" "kai" {
  name                     = "kaisa"
  resource_group_name      = azurerm_resource_group.kai.name
  location                 = azurerm_resource_group.kai.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_batch_account" "kai" {
  name                                = "kaiba"
  resource_group_name                 = azurerm_resource_group.kai.name
  location                            = azurerm_resource_group.kai.location
  pool_allocation_mode                = "BatchService"
  storage_account_id                  = azurerm_storage_account.kai.id
  storage_account_authentication_mode = "StorageKeys"
}

resource "azurerm_batch_application" "kai" {
  name                = "kai-batch-application"
  resource_group_name = azurerm_resource_group.kai.name
  account_name        = azurerm_batch_account.kai.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
data "azurerm_client_config" "current" {}

resource "random_string" "azurerm_key_vault_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

locals {
  current_user_id = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_key_vault" "vault" {
  name                       = coalesce(var.vault_name, "vault-${random_string.azurerm_key_vault_name.result}")
  location                   = azurerm_resource_group.kai.location
  resource_group_name        = azurerm_resource_group.kai.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.current_user_id

    key_permissions    = var.key_permissions
    secret_permissions = var.secret_permissions
  }
}

resource "random_string" "azurerm_key_vault_key_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_key_vault_key" "key" {
  name = coalesce(var.key_name, "key-${random_string.azurerm_key_vault_key_name.result}")

  key_vault_id = azurerm_key_vault.vault.id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = var.key_ops

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "kaisa" {
  name                = "kai-sa-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.kai.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaiba" {
  name                = "kai-ba-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_batch_account.kai.id
    subresource_names              = ["batchAccount"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaikv" {
  name                = "kai-kv-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaidb" {
  name                = "kai-db-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_server.kai.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaife" {
  name                = "kai-fe-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_linux_web_app.kaifrontend.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "kaibe" {
  name                = "kai-be-endpoint"
  location            = azurerm_resource_group.kai.location
  resource_group_name = azurerm_resource_group.kai.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    name                           = "kai-privateserviceconnection"
    private_connection_resource_id = azurerm_linux_web_app.kaibackend.id
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

# resource "azurerm_monitor_action_group" "main" {
#   name                = "kai-actiongroup"
#   resource_group_name = azurerm_resource_group.kai.name
#   short_name          = "p0action"

#   webhook_receiver {
#     name        = "callmyapi"
#     service_uri = "http://example.com/alert"
#   }
# }

# resource "azurerm_monitor_activity_log_alert" "main" {
#   name                = "kai-activitylogalert"
#   resource_group_name = azurerm_resource_group.kai.name
#   scopes              = [azurerm_resource_group.kai.id]
#   description         = "This alert will monitor a specific storage account updates."

#   criteria {
#     resource_id    = azurerm_storage_account.kai.id
#     operation_name = "Microsoft.Storage/storageAccounts/write"
#     category       = "Recommendation"
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id

#     webhook_properties = {
#       from = "terraform"
#     }
#   }
# }
