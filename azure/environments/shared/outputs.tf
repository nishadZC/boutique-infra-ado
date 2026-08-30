output "acr_login_server" {
  value       = module.acr.login_server
  description = "Non-prod ACR login server (dev/qa/staging). CI pipelines push images here."
}

output "acr_id" {
  value       = module.acr.id
  description = "Non-prod ACR resource ID. Used to grant AcrPull to dev/qa/staging AKS clusters."
}

output "acr_prod_login_server" {
  value       = module.acr_prod.login_server
  description = "Prod ACR login server. Only promoted images land here via the pipeline."
}

output "acr_prod_id" {
  value       = module.acr_prod.id
  description = "Prod ACR resource ID. Used to grant AcrPull to prod AKS cluster only."
}

output "sonarqube_public_ip" {
  value       = module.sonarqube.public_ip
  description = "Public IP of the SonarQube VM. Access on port 9000."
}
