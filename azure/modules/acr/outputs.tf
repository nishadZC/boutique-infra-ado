output "login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "The login server URL for the ACR."
}

output "id" {
  value       = azurerm_container_registry.acr.id
  description = "The resource ID of the ACR."
}
