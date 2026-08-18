resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

module "network" {
  source                 = "../../modules/network"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  vnet_name              = "${var.prefix}-vnet"
  address_space          = ["10.2.0.0/16"]
  aks_subnet_prefix      = "10.2.1.0/24"
  appgw_subnet_prefix    = "10.2.2.0/24"
  postgres_subnet_prefix = "10.2.3.0/24"
  bastion_subnet_prefix  = "10.2.4.0/24"
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

module "keyvault" {
  source              = "../../modules/keyvault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  keyvault_name       = "${var.prefix}-kv-2026x"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  aks_principal_id    = module.aks.kubelet_identity_object_id
}

