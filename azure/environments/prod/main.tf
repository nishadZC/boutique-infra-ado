resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

module "network" {
  source                 = "../../modules/network"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  vnet_name              = "${var.prefix}-vnet"
  address_space          = var.vnet_address_space
  aks_subnet_prefix      = var.aks_subnet_prefix
  appgw_subnet_prefix    = var.appgw_subnet_prefix
  postgres_subnet_prefix = var.postgres_subnet_prefix
  bastion_subnet_prefix  = var.bastion_subnet_prefix
  bastion_name           = "${var.prefix}-bastion"
}

module "app_gateway" {
  source              = "../../modules/app_gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_gateway_name    = "${var.prefix}-appgw"
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.appgw_subnet_id
}

module "aks" {
  source              = "../../modules/aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  cluster_name        = "${var.prefix}-aks"
  dns_prefix          = "${var.prefix}-aks"
  subnet_id           = module.network.aks_subnet_id
  app_gateway_id      = module.app_gateway.id
}


module "postgres" {
  source              = "../../modules/postgres"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = "${var.prefix}-pg"
  admin_username      = "postgres"
  admin_password      = var.db_password
  vnet_id             = module.network.vnet_id
  subnet_id           = module.network.postgres_subnet_id
}

data "azurerm_client_config" "current" {}

data "azurerm_container_registry" "shared_acr" {
  name                = "boutiqueacrshared"
  resource_group_name = "boutique-shared-rg"
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.shared_acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "random_string" "kv_suffix" {
  length  = 5
  special = false
  upper   = false
}

module "keyvault" {
  source              = "../../modules/keyvault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  keyvault_name       = "${var.prefix}-kv-${random_string.kv_suffix.result}"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  aks_principal_id    = module.aks.kubelet_identity_object_id
}

# Install ArgoCD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.8"

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}

# Workload Identity configuration
resource "azurerm_user_assigned_identity" "app_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "${var.prefix}-app-identity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_federated_identity_credential" "app_fic" {
  name                = "${var.prefix}-app-fic"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.app_identity.id
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

resource "azurerm_key_vault_access_policy" "terraform_policy" {
  key_vault_id = module.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

resource "azurerm_key_vault_secret" "pagerduty_key" {
  name         = "pagerduty-key"
  value        = var.pagerduty_key
  key_vault_id = module.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform_policy]
}

