output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}




output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "keyvault_uri" {
  value = module.keyvault.vault_uri
}
