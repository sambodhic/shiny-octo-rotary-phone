resource "azurerm_virtual_network" "kai" {
  name                = "kai-network"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.1.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "kaiDatabaseSubnet"
  resource_group_name = var.resource_group_name
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

resource "azurerm_public_ip" "publicip" {
  name                = "kai-pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
}
