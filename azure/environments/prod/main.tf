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
  bastion_subnet_prefix  = var.bastion_subnet_prefix
  bastion_name           = "${var.prefix}-bastion"
}

module "app_gateway" {
  source              = "../../modules/app_gateway"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  app_gateway_name    = "${var.prefix}-appgw"
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.appgw_subnet_id
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

# Prod pulls images exclusively from the prod ACR (promoted via pipeline from shared ACR)
data "azurerm_container_registry" "prod_acr" {
  name                = "boutiqueacrprod"
  resource_group_name = "boutique-shared-rg"
}

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


module "identity" {
  source                               = "../../modules/identity"
  prefix                               = var.prefix
  resource_group_name                  = module.resource_group.name
  location                             = module.resource_group.location
  oidc_issuer_url                      = module.aks.oidc_issuer_url
  key_vault_id                         = module.keyvault.id
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  dns_zone_id                          = data.azurerm_dns_zone.dns.id
  app_gateway_id                       = module.app_gateway.id
  appgw_subnet_id                      = module.network.appgw_subnet_id
  resource_group_id                    = module.resource_group.id
  prod_acr_id                          = data.azurerm_container_registry.prod_acr.id
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
  })
  key_vault_id = module.keyvault.id
  depends_on = [
    module.identity.app_identity_policy_id,
  ]
}
resource "azurerm_key_vault_secret" "pagerduty_key" {
  name         = "pagerduty-key"
  value        = var.pagerduty_key
  key_vault_id = module.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform_policy]
}

data "azurerm_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}



resource "azurerm_dns_a_record" "subdomain" {
  name                = "prod"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  records             = [module.app_gateway.public_ip_address]
}
