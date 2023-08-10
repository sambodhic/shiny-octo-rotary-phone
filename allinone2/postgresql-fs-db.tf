# resource "azurerm_postgresql_flexible_server_database" "database" {
#   name      = "${var.database_name_prefix}-db"
#   server_id = azurerm_postgresql_flexible_server.database.id
#   collation = "en_US.UTF8"
#   charset   = "UTF8"
# }