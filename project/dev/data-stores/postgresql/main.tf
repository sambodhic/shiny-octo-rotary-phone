resource "random_password" "pass" {
  length = 20
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_server.html
resource "azurerm_postgresql_server" "kaidb" {
  name                = "postgresql-server-kai"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

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

resource "azurerm_postgresql_database" "kaidb" {
  name                = "kaidb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.kaidb.name
  collation           = "English_United States.1252"
  charset             = "UTF8"
}