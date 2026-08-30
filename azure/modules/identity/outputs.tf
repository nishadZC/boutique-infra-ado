output "app_identity_client_id" {
  description = "The Client ID of the App Identity"
  value       = azurerm_user_assigned_identity.app_identity.client_id
}

output "cert_manager_identity_client_id" {
  description = "The Client ID of the Cert Manager Identity"
  value       = azurerm_user_assigned_identity.cert_manager_identity.client_id
}

output "app_identity_policy_id" {
  description = "The ID of the Key Vault Access Policy for App Identity"
  value       = azurerm_key_vault_access_policy.app_identity_policy.id
}
