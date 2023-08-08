# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

provider "azapi" {
}

resource "azurerm_resource_group" "kai-rg" {
  name     = "kai-resources"
  location = "West US 3"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_container_registry" "kai-acr" {
  name                = "kaiacr"
  resource_group_name = azurerm_resource_group.kai-rg.name
  location            = azurerm_resource_group.kai-rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# creating log analytics workspace
resource "azurerm_log_analytics_workspace" "kai-law" {
  name                = "kai-law"
  resource_group_name = azurerm_resource_group.kai-rg.name
  location            = azurerm_resource_group.kai-rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# creating aca environment
resource "azapi_resource" "kai-aca" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  parent_id = azurerm_resource_group.kai-rg.id
  location  = azurerm_resource_group.kai-rg.location
  name      = "kai-aca"

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.kai-law.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.kai-law.primary_shared_key
        }
      }
    }
  })
}

# creating the aca app
resource "azapi_resource" "kai-app" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = azurerm_resource_group.kai-rg.id
  location  = azurerm_resource_group.kai-rg.location
  name      = "kai-app"

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.kai-aca.id
      configuration = {
        ingress = {
          external   = true
          targetPort = 80
        }
        registries = [
          {
            server : "kaiacr.azurecr.io"
            username : "kaiacr"
            passwordSecretRef : "registry-password"
          }
        ]
        secrets = [
          {
            name : "registry-password"
            value : azurerm_container_registry.kai-acr.admin_password
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "web"
            image = "nginx"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          },
          # Only run it after kaiacr.azurecr.io/app is deployed
          # {
          #   name  = "app"
          #   image = "kaiacr.azurecr.io/app:latest"
          #   resources = {
          #     cpu    = 0.25
          #     memory = "0.5Gi"
          #   }
          # }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })
}


resource "azurerm_virtual_network" "kai-vm" {
  name                = "kai-network"
  location            = azurerm_resource_group.kai-rg.location
  resource_group_name = azurerm_resource_group.kai-rg.name
  address_space       = ["10.123.0.0/16"]
  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "kai-subnet" {
  name                 = "kai-subnet"
  resource_group_name  = azurerm_resource_group.kai-rg.name
  virtual_network_name = azurerm_virtual_network.kai-vm.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "kai-sg" {
  name                = "kai-sg"
  location            = azurerm_resource_group.kai-rg.location
  resource_group_name = azurerm_resource_group.kai-rg.name
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "kai-dev-rule" {
  name                        = "kai-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.kai-rg.name
  network_security_group_name = azurerm_network_security_group.kai-sg.name
}

resource "azurerm_public_ip" "kai-ip" {
  name                = "kai-ip"
  resource_group_name = azurerm_resource_group.kai-rg.name
  location            = azurerm_resource_group.kai-rg.location
  allocation_method   = "Dynamic"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "kai-nic" {
  name                = "kai-nic"
  location            = azurerm_resource_group.kai-rg.location
  resource_group_name = azurerm_resource_group.kai-rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kai-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kai-ip.id
  }
  tags = {
    environment = "dev"
  }
}