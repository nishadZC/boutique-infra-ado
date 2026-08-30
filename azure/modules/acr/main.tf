resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Industry standard: disable admin account — use RBAC (AcrPull/AcrPush) via Managed Identities
  admin_enabled = false

  tags = var.tags
}
