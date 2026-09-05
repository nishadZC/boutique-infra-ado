resource "azurerm_user_assigned_identity" "app_identity" {
  location            = var.location
  name                = "${var.prefix}-app-identity"
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "app_fic" {
  name                = "${var.prefix}-app-fic"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.app_identity.id
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_user_assigned_identity" "cert_manager_identity" {
  location            = var.location
  name                = "${var.prefix}-cert-manager-identity"
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "cert_manager_fic" {
  name                = "${var.prefix}-cert-manager-fic"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.cert_manager_identity.id
  subject             = "system:serviceaccount:cert-manager:cert-manager"
}

resource "azurerm_key_vault_access_policy" "app_identity_policy" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                            = var.app_gateway_id
  role_definition_name             = "Contributor"
  principal_id                     = var.ingress_application_gateway_identity
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                            = var.resource_group_id
  role_definition_name             = "Reader"
  principal_id                     = var.ingress_application_gateway_identity
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_network_contributor" {
  scope                            = var.appgw_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = var.ingress_application_gateway_identity
  skip_service_principal_aad_check = true
}

# Grant AcrPull on the correct ACR:
# - prod environment: pulls from prod_acr_id (isolated, only promoted images)
# - dev/qa/staging:   pulls from shared_acr_id (CI builds land here first)
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = coalesce(var.prod_acr_id, var.shared_acr_id)
  role_definition_name             = "AcrPull"
  principal_id                     = var.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cert_manager_dns_contributor" {
  scope                            = var.dns_zone_id
  role_definition_name             = "DNS Zone Contributor"
  principal_id                     = azurerm_user_assigned_identity.cert_manager_identity.principal_id
  skip_service_principal_aad_check = true
}
