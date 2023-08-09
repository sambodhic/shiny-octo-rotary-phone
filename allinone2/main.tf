resource "azurerm_resource_group" "kai" {
  name     = "kai-resources"
  location = "westus3"
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
  address_prefixes     = ["10.254.2.0/24"]
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