output "acr_login_server" {
  value = module.acr.login_server
}
output "acr_admin_username" {
  value = module.acr.admin_username
}
output "acr_admin_password" {
  value     = module.acr.admin_password
  sensitive = true
}

output "sonarqube_public_ip" {
  value = module.sonarqube.public_ip
}
