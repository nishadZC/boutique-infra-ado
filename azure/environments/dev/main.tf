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
  ssh_public_key      = var.ssh_public_key
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

resource "azurerm_key_vault_access_policy" "app_identity_policy" {
  key_vault_id = module.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
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

  lifecycle {
    # Prevent failure if this policy already exists in Azure from a prior run
    # Run: terraform import azurerm_key_vault_access_policy.terraform_policy <resource_id>
    # to bring it under Terraform management without recreating it.
    ignore_changes = all
  }
}

resource "azurerm_key_vault_secret" "db_secret" {
  name  = "boutique-db-secret"
  value = jsonencode({
    POSTGRES_HOST     = module.postgres.fqdn
    POSTGRES_DB       = "postgres"
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = var.db_password
    CLOUDINARY_CLOUD_NAME = var.cloudinary_cloud_name
    CLOUDINARY_API_KEY    = var.cloudinary_api_key
    CLOUDINARY_API_SECRET = var.cloudinary_api_secret
    GOOGLE_CLIENT_ID      = var.google_client_id
    AZURE_MAPS_SUBSCRIPTION_KEY = var.azure_maps_subscription_key
    RAZORPAY_KEY_ID       = var.razorpay_key_id
    RAZORPAY_KEY_SECRET   = var.razorpay_key_secret
  })
  key_vault_id = module.keyvault.id
  depends_on = [
    azurerm_key_vault_access_policy.terraform_policy,
    azurerm_key_vault_access_policy.app_identity_policy,
  ]
}

resource "azurerm_key_vault_secret" "pagerduty_key" {
  name         = "pagerduty-key"
  value        = var.pagerduty_key
  key_vault_id = module.keyvault.id
  depends_on = [
    azurerm_key_vault_access_policy.terraform_policy,
    azurerm_key_vault_access_policy.app_identity_policy,
  ]
}

# AGIC Role Assignments
# depends_on module.aks ensures role assignments are destroyed BEFORE AKS on terraform destroy
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = module.app_gateway.id
  role_definition_name = "Contributor"
  principal_id         = module.aks.ingress_application_gateway_identity
  depends_on           = [module.aks, module.app_gateway]
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = module.aks.ingress_application_gateway_identity
  depends_on           = [module.aks]
}

# ACR Pull Role Assignment
data "azurerm_container_registry" "shared_acr" {
  name                = "boutiqueacrshared"
  resource_group_name = "boutique-shared-rg"
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.shared_acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
  depends_on           = [module.aks]
}

resource "azurerm_role_assignment" "agic_network_contributor" {
  scope                = module.network.appgw_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.ingress_application_gateway_identity
  depends_on           = [module.aks, module.network]
}

data "azurerm_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_dns_a_record" "subdomain" {
  name                = "dev"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  records             = [module.app_gateway.public_ip_address]
}
