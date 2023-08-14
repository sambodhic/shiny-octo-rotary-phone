resource "azurerm_virtual_network" "kai" {
  name                = "${var.resource_group_name}-network"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "${var.resource_group_name}frontend"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "${var.resource_group_name}backend"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.kai.name
  address_prefixes     = ["10.254.1.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "${var.resource_group_name}DatabaseSubnet"
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
  name                = "${var.resource_group_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
}
