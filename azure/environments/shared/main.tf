resource "azurerm_resource_group" "shared_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}



module "acr" {
  source              = "../../modules/acr"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  acr_name            = "boutiqueacrshared"
}

resource "azurerm_virtual_network" "shared" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_subnet" "sonarqube" {
  name                 = "sonarqube-subnet"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [var.sonarqube_subnet_prefix]
}

module "sonarqube" {
  source              = "../../modules/sonarqube"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  vm_name             = "${var.prefix}-sonarqube"
  subnet_id           = azurerm_subnet.sonarqube.id
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
}
