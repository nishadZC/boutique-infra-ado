output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}




output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = "${var.prefix}-aks"
}

output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}

output "keyvault_uri" {
  value = module.keyvault.vault_uri
}
