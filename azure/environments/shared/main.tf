module "resource_group" {
  source   = "../../modules/resource_group"
  name     = "${var.prefix}-rg"
  location = var.location
}



# Non-prod ACR: used by dev, qa, staging
# CI pipeline builds and pushes images here
module "acr" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_name            = "boutiqueacrshared"
  tags = {
    purpose    = "non-prod"
    managed_by = "terraform"
  }
}

# Prod ACR: used exclusively by prod environment
# Only promoted, validated images are copied here via the pipeline
# CI pipelines have NO push access to this registry
module "acr_prod" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_name            = "boutiqueacrprod"
  sku                 = "Premium" # Premium required for geo-replication and private endpoints
  tags = {
    purpose    = "prod"
    managed_by = "terraform"
  }
}

resource "azurerm_virtual_network" "shared" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
}

resource "azurerm_subnet" "sonarqube" {
  name                 = "sonarqube-subnet"
  resource_group_name  = module.resource_group.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [var.sonarqube_subnet_prefix]
}

module "sonarqube" {
  source              = "../../modules/sonarqube"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vm_name             = "${var.prefix}-sonarqube"
  subnet_id           = azurerm_subnet.sonarqube.id
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  allowed_web_cidrs   = var.allowed_web_cidrs
}
