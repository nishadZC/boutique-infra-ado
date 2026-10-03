module "resource_group" {
  source   = "../../modules/resource_group"
  name     = "${var.prefix}-rg"
  location = var.location
}

module "network" {
  source                 = "../../modules/network"
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  vnet_name              = "${var.prefix}-vnet"
  address_space          = var.vnet_address_space
  aks_subnet_prefix      = var.aks_subnet_prefix
  appgw_subnet_prefix    = var.appgw_subnet_prefix
  postgres_subnet_prefix = var.postgres_subnet_prefix
}

module "app_gateway" {
  source              = "../../modules/app_gateway"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  app_gateway_name    = "${var.prefix}-appgw"
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.appgw_subnet_id
  domain_name_label   = "${var.prefix}-boutique"
}

module "aks" {
  source              = "../../modules/aks"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  cluster_name        = "${var.prefix}-aks"
  dns_prefix          = "${var.prefix}-aks"
  subnet_id           = module.network.aks_subnet_id
  app_gateway_id      = module.app_gateway.id
  ssh_public_key      = var.ssh_public_key
}

module "postgres" {
  source              = "../../modules/postgres"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
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
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  keyvault_name       = "${var.prefix}-kv-${random_string.kv_suffix.result}"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  aks_principal_id    = module.aks.kubelet_identity_object_id
}

module "acr" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_name            = var.acr_name
  tags = {
    purpose    = "staging"
    managed_by = "terraform"
  }
}

module "identity" {
  source                               = "../../modules/identity"
  prefix                               = var.prefix
  resource_group_name                  = module.resource_group.name
  location                             = module.resource_group.location
  oidc_issuer_url                      = module.aks.oidc_issuer_url
  key_vault_id                         = module.keyvault.id
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  app_gateway_id                       = module.app_gateway.id
  appgw_subnet_id                      = module.network.appgw_subnet_id
  resource_group_id                    = module.resource_group.id
  shared_acr_id                        = module.acr.id
  ingress_application_gateway_identity = module.aks.ingress_application_gateway_identity
  kubelet_identity_object_id           = module.aks.kubelet_identity_object_id
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
    ignore_changes = all
  }
}

resource "random_password" "internal_api_token" {
  length  = 48
  special = false
}

resource "azurerm_key_vault_secret" "db_secret" {
  name = "boutique-db-secret"
  value = jsonencode({
    POSTGRES_HOST               = module.postgres.fqdn
    POSTGRES_DB                 = "postgres"
    POSTGRES_USER               = "postgres"
    POSTGRES_PASSWORD           = var.db_password
    CLOUDINARY_CLOUD_NAME       = var.cloudinary_cloud_name
    CLOUDINARY_API_KEY          = var.cloudinary_api_key
    CLOUDINARY_API_SECRET       = var.cloudinary_api_secret
    GOOGLE_CLIENT_ID            = var.google_client_id
    AZURE_MAPS_SUBSCRIPTION_KEY = var.azure_maps_subscription_key
    RAZORPAY_KEY_ID             = var.razorpay_key_id
    RAZORPAY_KEY_SECRET         = var.razorpay_key_secret
    JWT_SECRET                  = var.jwt_secret
    INTERNAL_API_TOKEN          = random_password.internal_api_token.result
    ADMIN_EMAIL                 = var.admin_email
    ADMIN_INITIAL_PASSWORD      = var.admin_initial_password
  })
  key_vault_id = module.keyvault.id
  depends_on = [
    azurerm_key_vault_access_policy.terraform_policy,
    module.identity.app_identity_policy_id,
  ]
}

resource "azurerm_key_vault_secret" "pagerduty_key" {
  name         = "pagerduty-key"
  value        = var.pagerduty_key
  key_vault_id = module.keyvault.id
  depends_on = [
    azurerm_key_vault_access_policy.terraform_policy,
    module.identity.app_identity_policy_id,
  ]
}

