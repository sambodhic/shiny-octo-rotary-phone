output "name" {
    value = azurerm_virtual_network.kai.name
}

output "backend" {
    value = azurerm_subnet.backend
}

output "frontend" {
    value = azurerm_subnet.frontend
}

output "publicip" {
    value = azurerm_public_ip.publicip
}