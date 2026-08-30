output "id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "ingress_application_gateway_identity" {
  value = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "host" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.host
  sensitive = true
}

output "client_certificate" {
  value     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  sensitive = true
}

output "client_key" {
  value     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  sensitive = true
}
output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}
