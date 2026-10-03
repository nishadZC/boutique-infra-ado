output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "resource_group_name" {
  value = module.resource_group.name
}

output "cluster_name" {
  value = "${var.prefix}-aks"
}

output "app_gateway_public_ip" {
  value = module.app_gateway.public_ip_address
}

output "app_gateway_fqdn" {
  value       = module.app_gateway.fqdn
  description = "Free Azure-provided hostname (*.cloudapp.azure.com) for this environment's public IP - use this instead of the raw IP until a real domain is set up."
}

output "app_identity_client_id" {
  value = module.identity.app_identity_client_id
}

output "cert_manager_client_id" {
  value = module.identity.cert_manager_identity_client_id
}

output "keyvault_uri" {
  value = module.keyvault.vault_uri
}

output "azure_maps_primary_access_key" {
  value       = module.maps.primary_access_key
  sensitive   = true
  description = "Primary subscription key for the dev-only Terraform-managed Azure Maps account."
}

