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

output "app_identity_client_id" {
  value = module.identity.app_identity_client_id
}

output "cert_manager_client_id" {
  value = module.identity.cert_manager_identity_client_id
}

output "keyvault_uri" {
  value = module.keyvault.vault_uri
}
