output "id" {
  value = azurerm_application_gateway.appgw.id
}

output "public_ip_address" {
  value = azurerm_public_ip.appgw.ip_address
}

output "fqdn" {
  value = azurerm_public_ip.appgw.fqdn
}
