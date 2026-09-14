output "id" {
  value       = azurerm_maps_account.maps.id
  description = "The ID of the Azure Maps Account."
}

output "primary_access_key" {
  value       = azurerm_maps_account.maps.primary_access_key
  sensitive   = true
  description = "The primary subscription key for the Azure Maps account."
}
